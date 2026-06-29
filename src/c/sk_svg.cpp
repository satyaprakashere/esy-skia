/*
 * Copyright 2014 Google Inc.
 * Copyright 2015 Xamarin Inc.
 * Copyright 2017 Microsoft Corporation. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include "include/svg/SkSVGCanvas.h"

#ifdef ESY_SKIA_SVG
#include "modules/svg/include/SkSVGDOM.h"
#include "modules/svg/include/SkSVGNode.h"
#endif

#include "include/c/sk_svg.h"

#include "src/c/sk_types_priv.h"

sk_canvas_t* sk_svgcanvas_create_with_stream(const sk_rect_t* bounds, sk_wstream_t* stream) {
    return ToCanvas(SkSVGCanvas::Make(*AsRect(bounds), AsWStream(stream)).release());
}

#ifdef ESY_SKIA_SVG
void sk_svgdom_render(sk_svgdom_t *svgdom, sk_canvas_t *canvas) {
    AsSVGDOM(svgdom)->render(AsCanvas(canvas));
}

void sk_svgdom_set_container_size(sk_svgdom_t *svgdom, float width, float height) {
    AsSVGDOM(svgdom)->setContainerSize(SkSize::Make(width, height));
}

float sk_svgdom_get_container_width(sk_svgdom_t *svgdom) {
    return AsSVGDOM(svgdom)->containerSize().width();
}

float sk_svgdom_get_container_height(sk_svgdom_t *svgdom) {
    return AsSVGDOM(svgdom)->containerSize().height();
}

sk_svgdom_t *sk_svgdom_create_from_stream(sk_stream_t *stream) {
    return ToSVGDOM(SkSVGDOM::MakeFromStream(*AsStream(stream)).release());
}

void sk_svgdom_ref(const sk_svgdom_t *svg) {
    SkSafeRef(AsSVGDOM(svg));
}

void sk_svgdom_unref(const sk_svgdom_t *svg) {
    SkSafeUnref(AsSVGDOM(svg));
}
#endif
