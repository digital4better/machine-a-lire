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
struct Detection *create_detection(double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4) {
    struct Detection *detection = (struct Detection *)malloc(sizeof(struct Detection));
    detection->x1 = x1;
    detection->y1 = y1;
    detection->x2 = x2;
    detection->y2 = y2;
    detection->x3 = x3;
    detection->y3 = y3;
    detection->x4 = x4;
    detection->y4 = y4;
    return detection;
}

Detection* EMPTY = create_detection(0, 0, 0, 0, 0, 0, 0, 0);

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Detection *detect_quad(uint8_t *buf, int32_t width, int32_t height) {
    cv::Mat bgra(height, width, CV_8UC4, buf);
    cv::Mat img;
    cv::cvtColor(bgra, img, cv::COLOR_BGRA2GRAY);

    if (img.size().width == 0 || img.size().height == 0) {
        return EMPTY;
    }

    // Blurring to enhance edge detection
    cv::medianBlur(img, img, 3);
    cv::Mat gray(img.size(), CV_8U);

    // Detect quads
    std::vector<std::vector<cv::Point> > contours;
    double high = cv::threshold(img, gray, 0, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);
    double low = 0.5 * high;

	cv::Canny(img, gray, low, high);
    cv::dilate(gray, gray, cv::Mat(), cv::Point(-1, -1));
    cv::findContours(gray, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
    std::vector<cv::Point> approx;
    std::vector<cv::Point> biggest;
    float biggestArea = 0;
    for (const auto & contour : contours) {
        cv::approxPolyDP(cv::Mat(contour), approx, cv::arcLength(cv::Mat(contour), true) * 0.02, true);
        float area = std::fabs(cv::contourArea(cv::Mat(approx))) / (width * height);
        // Quad must have 4 edges, is convex and cover 10-80% of the screen
        if (approx.size() == 4 && area > 0.1 && area < 0.8 && cv::isContourConvex(cv::Mat(approx))) {
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
            if (maxCosine < 0.3 && biggestArea < area) {
                biggest = approx;
                biggestArea = area;
            }
        }
    }
    if (biggestArea == 0) {
        return EMPTY;
    }
    return create_detection(
        (double) biggest[0].x / width, (double) biggest[0].y / height,
        (double) biggest[1].x / width, (double) biggest[1].y / height,
        (double) biggest[2].x / width, (double) biggest[2].y / height,
        (double) biggest[3].x / width, (double) biggest[3].y / height
    );
}
