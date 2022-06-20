#include <iostream>
#include <vector>
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

struct Detection {
    double x1;
    double y1;
    double x2;
    double y2;
    double x3;
    double y3;
    double x4;
    double y4;
};

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Detection *create_detection(std::vector<cv::Point> &quad, int width, int height) {
    struct Detection *detection = (struct Detection *)malloc(sizeof(struct Detection));
    detection->x1 = (double) quad[0].x / width;
    detection->y1 = (double) quad[0].y / height;
    detection->x2 = (double) quad[1].x / width;
    detection->y2 = (double) quad[1].y / height;
    detection->x3 = (double) quad[2].x / width;
    detection->y3 = (double) quad[2].y / height;
    detection->x4 = (double) quad[3].x / width;
    detection->y4 = (double) quad[3].y / height;
    return detection;
}

Detection EMPTY = {0, 0, 0, 0, 0, 0, 0, 0};

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void prepare(cv::Mat &in) {
    // Blurring to enhance edge detection
    cv::medianBlur(in, in, 11);
    // Auto selecting canny parameters
    double high = cv::threshold(in, cv::Mat(in.size(), CV_8U), 0, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);
    double low = 0.5 * high;
    // Edge detection and enhancement
	cv::Canny(in, in, low, high);
    cv::dilate(in, in, cv::Mat(), cv::Point(-1, -1));
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Detection *detect_quad_by_contours(cv::Mat &image, int width, int height) {
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(image, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    std::vector<cv::Point> approx;
    std::vector<cv::Point> quad;
    float quadArea = 0;
    for (const auto & contour : contours) {
        cv::approxPolyDP(cv::Mat(contour), approx, cv::arcLength(cv::Mat(contour), true) * 0.02, true);
        float area = std::fabs(cv::contourArea(cv::Mat(approx))) / (width * height);
        // Quad must have 4 edges, be convex and cover 20-80% of the screen
        if (approx.size() == 4 && area > 0.2 && area < 0.8 && cv::isContourConvex(cv::Mat(approx))) {
            double maxCosine = 0;
            for (int j = 2; j < 5; j++) {
                cv::Point pt1 = approx[j % 4];
                cv::Point pt2 = approx[j - 2];
                cv::Point pt0 = approx[j - 1];
                double dx1 = pt1.x - pt0.x;
                double dy1 = pt1.y - pt0.y;
                double dx2 = pt2.x - pt0.x;
                double dy2 = pt2.y - pt0.y;
                double cosine = std::fabs((dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10));
                maxCosine = MAX(maxCosine, cosine);
            }
            if (maxCosine < 0.5 && quadArea < area) {
                quad = approx;
                quadArea = area;
            }
        }
    }
    if (quadArea > 0) {
        return create_detection(quad, width, height);
    }
    return nullptr;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
bool intersection(float r1, float t1, float r2, float t2, int width, int height, int &x, int &y) {
    // safe area to avoid image border detection
    const int safe = 10;
    // It must intersect with an angle between 60 et 120
    if (!(std::fabs(t1 - t2) >= CV_PI / 3 && std::fabs(t1 - t2) <= 2 * CV_PI / 3)) {
        return false;
    }
    float ct1 = std::cosf(t1);
    float st1 = std::sinf(t1);
    float ct2 = std::cosf(t2);
    float st2 = std::sinf(t2);
    float d = ct1 * st2 - st1 * ct2;
    // It must intersect
    if (d != 0.0f) {
        x = (int) ((st2 * r1 - st1 * r2) / d);
        y = (int) ((-ct2 * r1 + ct1 * r2) / d);
        // It must intersect in safe area
        if (x > safe && y > safe && x < width - safe && y < height - safe) {
            return true;
        }
    }
    return false;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Detection *detect_quad_by_lines(cv::Mat &image, int width, int height) {
    std::vector<cv::Point> quad;
    float quadArea = 0;

    std::vector<cv::Vec2f> lines;
    int x1, y1, x2, y2, x3, y3, x4, y4;

    // 4 steps max
    for (int t = width / 2; t >= width / 4 && quadArea == 0; t -= width / 16) {
        // Detecting line of minimum length t
        cv::HoughLines(image, lines, 1, CV_PI / 180, t);
        // Not enough lines
        if (lines.size() < 4) continue;
        // Too many lines
        if (lines.size() > 24) break;
        // Using line intersection to find quad
        for (size_t i1 = 0; i1 < lines.size(); i1++) {
            float rho1 = lines[i1][0], theta1 = lines[i1][1];
            for (size_t i2 = 0; i2 < lines.size(); i2++) {
                float rho2 = lines[i2][0], theta2 = lines[i2][1];
                if (intersection(rho1, theta1, rho2, theta2, width, height, x1, y1)) {
                    for (size_t i3 = 0; i3 < lines.size(); i3++) {
                        float rho3 = lines[i3][0], theta3 = lines[i3][1];
                        if (std::cosf(theta1 - theta3) > 0.94 &&
                            intersection(rho2, theta2, rho3, theta3, width, height, x2, y2)) {
                            for (size_t i4 = 0; i4 < lines.size(); i4++) {
                                float rho4 = lines[i4][0], theta4 = lines[i4][1];
                                if (std::cosf(theta2 - theta4) > 0.94 &&
                                    intersection(rho3, theta3, rho4, theta4, width, height, x3, y3) &&
                                    intersection(rho4, theta4, rho1, theta1, width, height, x4, y4)) {
                                    std::vector<cv::Point> contour{cv::Point(x1, y1), cv::Point(x2, y2), cv::Point(x3, y3), cv::Point(x4, y4)};
                                    // quad should be convex
                                    if (!cv::isContourConvex(contour)) continue;
                                    // quad should be positive (clockwise) and between 20-80% of image
                                    double area = cv::contourArea(contour, true) / (width * height);
                                    if (area < 0.2 or area > 0.8) continue;
                                    // keep smallest quad
                                    if (area < quadArea || quadArea == 0) {
                                      quadArea = area;
                                      quad = contour;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (quadArea > 0) {
        //return create_detection(quad, width, height);
        return create_detection(quad, width - width/4, height + height/4);
    }
    return nullptr;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Detection *detect_quad(uint8_t *buf, int32_t width, int32_t height) {
    if (width == 0 || height == 0) {
        return &EMPTY;
    }

    cv::Mat original(height + height/2, width, CV_8UC1, buf);
    double factor = 320.0 / width;
    width *= factor;
    height *= factor;
    cv::resize(original, original, cv::Size(), factor, factor);

    cv::Mat gray, hsv;
    cv::Mat channels[3];

    cv::cvtColor(original, original, cv::COLOR_YUV2BGR_I420);
    cv::cvtColor(original, gray, cv::COLOR_BGR2GRAY);
    prepare(gray);

    Detection *d1 = detect_quad_by_contours(gray, width, height);
    if (d1 != nullptr) return d1;

    Detection *d2 = detect_quad_by_lines(gray, width, height);
    if (d2 != nullptr) return d2;

    cv::cvtColor(original, hsv, cv::COLOR_BGR2HSV);
    cv::split(hsv, channels);
    prepare(channels[1]);

    Detection *d3 = detect_quad_by_contours(channels[1], width, height);
    if (d3 != nullptr) return d3;

    Detection *d4 = detect_quad_by_lines(channels[1], width, height);
    if (d4 != nullptr) return d4;

    return &EMPTY;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Detection *detect_quad_from_shot(char *path, int32_t width, int32_t height) {
    if (width == 0 || height == 0) {
        return &EMPTY;
    }

    cv::Mat original = cv::imread(path);

    double factor = 320.0 / width;
    width *= factor;
    height *= factor;
    cv::resize(original, original, cv::Size(), factor, factor);

    cv::Mat gray, hsv;
    cv::Mat channels[3];

    cv::cvtColor(original, gray, cv::COLOR_BGR2GRAY);
    prepare(gray);

    Detection *d1 = detect_quad_by_contours(gray, width, height);
    if (d1 != nullptr) return d1;

    Detection *d2 = detect_quad_by_lines(gray, width, height);
    if (d2 != nullptr) return d2;

    cv::cvtColor(original, hsv, cv::COLOR_BGR2HSV);
    cv::split(hsv, channels);
    prepare(channels[1]);

    Detection *d3 = detect_quad_by_contours(channels[1], width, height);
    if (d3 != nullptr) return d3;

    Detection *d4 = detect_quad_by_lines(channels[1], width, height);
    if (d4 != nullptr) return d4;

    return &EMPTY;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void warp_image(uint8_t *buf, int32_t width, int32_t height, double tl_x, double tl_y, double tr_x, double tr_y, double br_x, double br_y, double bl_x, double bl_y, char *path) {
    cv::Mat original(height, width, CV_8UC3, buf);

    cv::Mat warped, gray;
    cv::cvtColor(original, gray, cv::COLOR_BGR2GRAY);

    int maxWidth = width * MAX(sqrt((br_x - bl_x) * (br_x - bl_x) + (br_y - bl_y) * (br_y - bl_y)),
                       sqrt((tr_x - tl_x) * (tr_x - tl_x) + (tr_y - tl_y) * (tr_y - tl_y)));

    int maxHeight = height * MAX(sqrt((tr_x - br_x) * (tr_x - br_x) + (tr_y - br_y) * (tr_y - br_y)),
                        sqrt((tl_x - bl_x) * (tl_x - bl_x) + (tl_y - bl_y) * (tl_y - bl_y)));

    std::vector<cv::Point2f> source;
    source.push_back(cv::Point2f(tl_x * width, tl_y * height));
    source.push_back(cv::Point2f(tr_x * width, tr_y * height));
    source.push_back(cv::Point2f(br_x * width, br_y * height));
    source.push_back(cv::Point2f(bl_x * width, bl_y * height));

    std::vector<cv::Point2f> destination;
    destination.push_back(cv::Point2f(0, 0));
    destination.push_back(cv::Point2f(maxWidth - 1, 0));
    destination.push_back(cv::Point2f(maxWidth - 1, maxHeight - 1));
    destination.push_back(cv::Point2f(0, maxHeight - 1));

    cv::Mat transform = cv::getPerspectiveTransform(source, destination);

    cv::warpPerspective(gray, warped, transform, cv::Size(maxWidth, maxHeight), cv::INTER_LINEAR, cv::BORDER_CONSTANT);
    cv::adaptiveThreshold(warped, warped, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 21, 10);

    cv::imwrite(path, warped);

    printf("Warped image ! %s", path);
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void warp_shot(int32_t width, int32_t height, double tl_x, double tl_y, double tr_x, double tr_y, double br_x, double br_y, double bl_x, double bl_y, char *path) {
    cv::Mat original = cv::imread(path);

    double factor = 1080.0 / width;
    width *= factor;
    height *= factor;
    cv::resize(original, original, cv::Size(), factor, factor);

    cv::Mat warped, gray;
    cv::cvtColor(original, gray, cv::COLOR_BGR2GRAY);

    int maxWidth = width * MAX(sqrt((br_x - bl_x) * (br_x - bl_x) + (br_y - bl_y) * (br_y - bl_y)),
                       sqrt((tr_x - tl_x) * (tr_x - tl_x) + (tr_y - tl_y) * (tr_y - tl_y)));

    int maxHeight = height * MAX(sqrt((tr_x - br_x) * (tr_x - br_x) + (tr_y - br_y) * (tr_y - br_y)),
                        sqrt((tl_x - bl_x) * (tl_x - bl_x) + (tl_y - bl_y) * (tl_y - bl_y)));

    std::vector<cv::Point2f> source;
    source.push_back(cv::Point2f(tl_x * width, tl_y * height));
    source.push_back(cv::Point2f(tr_x * width, tr_y * height));
    source.push_back(cv::Point2f(br_x * width, br_y * height));
    source.push_back(cv::Point2f(bl_x * width, bl_y * height));

    std::vector<cv::Point2f> destination;
    destination.push_back(cv::Point2f(0, 0));
    destination.push_back(cv::Point2f(maxWidth - 1, 0));
    destination.push_back(cv::Point2f(maxWidth - 1, maxHeight - 1));
    destination.push_back(cv::Point2f(0, maxHeight - 1));

    cv::Mat transform = cv::getPerspectiveTransform(source, destination);

    cv::warpPerspective(gray, warped, transform, cv::Size(maxWidth, maxHeight), cv::INTER_LINEAR, cv::BORDER_CONSTANT);
    cv::adaptiveThreshold(warped, warped, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 21, 10);

    cv::imwrite(path, warped);

    printf("Warped image ! %s", path);
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void make_rotation(char *path) {

    cv::Mat original = cv::imread(path);
    cv::Mat rotated;

    cv::Point2f center(original.cols/2, original.rows/2);
    cv::Mat rotation = cv::getRotationMatrix2D(center, 180, 1.0);

    cv::warpAffine(original, rotated, rotation, original.size());

    cv::imwrite(path, rotated);
}