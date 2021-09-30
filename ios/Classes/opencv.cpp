#include <iostream>
#include <vector>
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

struct Quad {
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
struct Quad *create_quad(double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4) {
    struct Quad *quad = (struct Quad *)malloc(sizeof(struct Quad));
    quad->x1 = x1;
    quad->y1 = y1;
    quad->x2 = x2;
    quad->y2 = y2;
    quad->x3 = x3;
    quad->y3 = y3;
    quad->x4 = x4;
    quad->y4 = y4;
    return quad;
}

Quad* EMPTY = create_quad(0, 0, 0, 0, 0, 0, 0, 0);

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Quad *detect_quad(uint8_t *buf, int32_t width, int32_t height) {
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
    std::vector<std::vector<cv::Point>> quads;
    std::vector<std::vector<cv::Point> > contours;

    int thresholdLevels[] = {10, 30, 50, 70};
    for (int thresholdLevel : thresholdLevels) {
        cv::Canny(img, gray, thresholdLevel, thresholdLevel * 3, 3);
        cv::dilate(gray, gray, cv::Mat(), cv::Point(-1, -1));
        cv::findContours(gray, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
        std::vector<cv::Point> approx;
        for (const auto & contour : contours) {
            cv::approxPolyDP(cv::Mat(contour), approx, cv::arcLength(cv::Mat(contour), true) * 0.02, true);
            if (approx.size() == 4 && std::fabs(cv::contourArea(cv::Mat(approx))) > 1000 &&
                cv::isContourConvex(cv::Mat(approx))) {
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
                if (maxCosine < 0.3) {
                    quads.push_back(approx);
                }
            }
        }
    }

    // Select biggest quad
    std::vector<cv::Point>* biggest = NULL;
    float biggestWidth = 0;
    float biggestHeight = 0;

    // Sort clockwise
    struct sortY {
        bool operator() (cv::Point pt1, cv::Point pt2) { return (pt1.y < pt2.y);}
    } orderY;
    struct sortX {
        bool operator() (cv::Point pt1, cv::Point pt2) { return (pt1.x < pt2.x);}
    } orderX;

    for (int i = 0; i < quads.size(); i++) {
        std::vector<cv::Point>* quad = &quads[i];
        std::sort(quad->begin(), quad->end(), orderY);
        std::sort(quad->begin(), quad->begin() + 2, orderX);
        std::sort(quad->begin() + 2, quad->end(), orderX);
        float quadWidth = std::max((*quad)[3].x - (*quad)[0].x, (*quad)[1].x - (*quad)[2].x);
        float quadHeight = std::max((*quad)[3].y - (*quad)[0].y, (*quad)[1].y - (*quad)[2].y);
        if (quadWidth < width / 5 || quadHeight < height / 5) {
            continue;
        }
        if (quadWidth > width * 0.99 || quadHeight > height * 0.99) {
            continue;
        }
        if (quadWidth * quadHeight >= biggestWidth * biggestHeight) {
            biggest = quad;
            biggestWidth = quadWidth;
            biggestHeight = quadHeight;
        }
    }
    if (biggest == NULL) {
        return EMPTY;
    }
    return create_quad(
        (double) (*biggest)[0].x / width, (double) (*biggest)[0].y / height,
        (double) (*biggest)[1].x / width, (double) (*biggest)[1].y / height,
        (double) (*biggest)[2].x / width, (double) (*biggest)[2].y / height,
        (double) (*biggest)[3].x / width, (double) (*biggest)[3].y / height
    );
}
