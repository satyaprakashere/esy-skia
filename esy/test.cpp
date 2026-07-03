#include "include/core/SkSurface.h"
#include "include/core/SkPath.h"
#include "include/core/SkPathBuilder.h"
#include "include/core/SkCanvas.h"
#include "include/core/SkData.h"
#include "include/core/SkImage.h"
#include "include/core/SkStream.h"
#include "include/encode/SkPngEncoder.h"

int main (int argc, char * const argv[]) {
  const char * filePath = argv[1];
  int width = 256;
  int height = 256;

  // create canvas to draw on
  sk_sp<SkSurface> rasterSurface = SkSurfaces::Raster(SkImageInfo::MakeN32Premul(width, height));
  SkCanvas* canvas = rasterSurface->getCanvas();

  // creating a path to be drawn
  SkPathBuilder builder;
  builder.moveTo(10.0f, 10.0f);
  builder.lineTo(100.0f, 0.0f);
  builder.lineTo(100.0f, 100.0f);
  builder.lineTo(0.0f, 100.0f);
  builder.lineTo(50.0f, 50.0f);
  builder.close();
  SkPath path = builder.detach();

  // creating a paint to draw with
  SkPaint p;
  p.setAntiAlias(true);

  // clear out which may be was drawn before and draw the path
  canvas->clear(SK_ColorWHITE);
  canvas->drawPath(path, p);

  // make a PNG encoded image using the canvas
  sk_sp<SkImage> img(rasterSurface->makeImageSnapshot());
  if (!img) { return 1; }
  sk_sp<SkData> png(SkPngEncoder::Encode(nullptr, img.get(), {}));
  if (!png) { return 1; }

  // write the data to the file specified by filePath
  SkFILEWStream out(filePath);
  (void)out.write(png->data(), png->size());

  return 0;
}