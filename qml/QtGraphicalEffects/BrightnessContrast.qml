/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Graphical Effects module.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtGraphicalEffects.private 1.0

/*!
    \qmltype BrightnessContrast
    \inqmlmodule QtGraphicalEffects
    \since QtGraphicalEffects 1.0
    \inherits QtQuick2::Item
    \ingroup qtgraphicaleffects-color
    \brief Adjusts brightness and contrast.

    This effect adjusts the source item colors.
    Brightness adjustment changes the perceived luminance of the source item.
    Contrast adjustment increases or decreases the color
    and brightness variations.

    \table
    \header
        \li Source
        \li Effect applied
    \row
        \li \image Original_bug.png
        \li \image BrightnessContrast_bug.png
    \endtable

    \note This effect is available when running with OpenGL.

    \section1 Example

    The following example shows how to apply the effect.
    \snippet BrightnessContrast-example.qml example

*/
Item {
    id: rootItem

    /*!
        This property defines the source item that provides the source pixels
        for the effect.

        \note It is not supported to let the effect include itself, for
        instance by setting source to the effect's parent.
    */
    property variant source

    /*!
        This property defines how much the source brightness is increased or
        decreased.

        The value ranges from -1.0 to 1.0. By default, the property is set to \c
        0.0 (no change).

        \table
        \header
        \li Output examples with different brightness values
        \li
        \li
        \row
            \li \image BrightnessContrast_brightness1.png
            \li \image BrightnessContrast_brightness2.png
            \li \image BrightnessContrast_brightness3.png
        \row
            \li \b { brightness: -0.25 }
            \li \b { brightness: 0 }
            \li \b { brightness: 0.5 }
        \row
            \li \l contrast: 0
            \li \l contrast: 0
            \li \l contrast: 0
        \endtable

    */
    property real brightness: 0.0

    /*!
        This property defines how much the source contrast is increased or
        decreased. The decrease of the contrast is linear, but the increase is
        applied with a non-linear curve to allow very high contrast adjustment at
        the high end of the value range.

        \table
        \header
            \li Contrast adjustment curve
        \row
            \li \image BrightnessContrast_contrast_graph.png
        \endtable

       The value ranges from -1.0 to 1.0. By default, the property is set to \c 0.0 (no change).

        \table
        \header
        \li Output examples with different contrast values
        \li
        \li
        \row
            \li \image BrightnessContrast_contrast1.png
            \li \image BrightnessContrast_contrast2.png
            \li \image BrightnessContrast_contrast3.png
        \row
            \li \b { contrast: -0.5 }
            \li \b { contrast: 0 }
            \li \b { contrast: 0.5 }
        \row
            \li \l brightness: 0
            \li \l brightness: 0
            \li \l brightness: 0
        \endtable

    */
    property real contrast: 0.0

    /*!
        This property allows the effect output pixels to be cached in order to
        improve the rendering performance.

        Every time the source or effect properties are changed, the pixels in
        the cache must be updated. Memory consumption is increased, because an
        extra buffer of memory is required for storing the effect output.

        It is recommended to disable the cache when the source or the effect
        properties are animated.

        By default, the property is set to \c false.

    */
    property bool cached: false

    SourceProxy {
        id: sourceProxy
        input: rootItem.source
    }

    ShaderEffectSource {
        id: cacheItem
        anchors.fill: parent
        visible: rootItem.cached
        smooth: true
        sourceItem: shaderItem
        live: true
        hideSource: visible
    }

    ShaderEffect {
        id: shaderItem
        property variant source: sourceProxy.output
        property real brightness: rootItem.brightness
        property real contrast: rootItem.contrast

        anchors.fill: parent
        blending: !rootItem.cached

        fragmentShader: "
            varying mediump vec2 qt_TexCoord0;
            uniform highp float qt_Opacity;
            uniform lowp sampler2D source;
            uniform highp float brightness;
            uniform highp float contrast;
            void main() {
                highp vec4 pixelColor = texture2D(source, qt_TexCoord0);
                pixelColor.rgb /= max(1.0/256.0, pixelColor.a);
                highp float c = 1.0 + contrast;
                highp float contrastGainFactor = 1.0 + c * c * c * c * step(0.0, contrast);
                pixelColor.rgb = ((pixelColor.rgb - 0.5) * (contrastGainFactor * contrast + 1.0)) + 0.5;
                pixelColor.rgb = mix(pixelColor.rgb, vec3(step(0.0, brightness)), abs(brightness));
                gl_FragColor = vec4(pixelColor.rgb * pixelColor.a, pixelColor.a) * qt_Opacity;
            }
        "
    }
}
