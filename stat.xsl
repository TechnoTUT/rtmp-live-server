<?xml version="1.0" encoding="utf-8" ?>


<!--
   Copyright (C) Roman Arutyunyan
-->


<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/">
    <html>
        <head>
            <title>RTMP statistics</title>
            <script type="text/javascript">
                <![CDATA[
                var refreshTimer = null;
                var xslDoc = null;

                function loadXsl(callback) {
                    if (xslDoc) { callback(xslDoc); return; }
                    var xhttp = new XMLHttpRequest();
                    xhttp.open("GET", "/stat.xsl", true);
                    xhttp.onload = function() {
                        if (xhttp.status === 200) {
                            xslDoc = xhttp.responseXML;
                            callback(xslDoc);
                        }
                    };
                    xhttp.send("");
                }

                function morphNode(curr, next) {
                    if (curr.nodeType === 3 && next.nodeType === 3) {
                        if (curr.nodeValue !== next.nodeValue) {
                            curr.nodeValue = next.nodeValue;
                        }
                        return;
                    }
                    if (curr.nodeType !== 1 || next.nodeType !== 1 || curr.nodeName !== next.nodeName) {
                        curr.parentNode.replaceChild(next.cloneNode(true), curr);
                        return;
                    }
                    // Sync attributes (except inline display style to keep open state)
                    var cAttrs = curr.attributes;
                    var nAttrs = next.attributes;
                    for (var i = 0; i < nAttrs.length; i++) {
                        var a = nAttrs[i];
                        if (a.name === "style" && curr.hasAttribute("id") && curr.nodeName === "TR") {
                            continue; // preserve expanded/collapsed state
                        }
                        if (curr.getAttribute(a.name) !== a.value) {
                            curr.setAttribute(a.name, a.value);
                        }
                    }
                    // Sync children
                    var cChildren = curr.childNodes;
                    var nChildren = next.childNodes;
                    var cLen = cChildren.length;
                    var nLen = nChildren.length;
                    var minLen = Math.min(cLen, nLen);
                    for (var j = 0; j < minLen; j++) {
                        morphNode(cChildren[j], nChildren[j]);
                    }
                    if (cLen < nLen) {
                        for (var k = cLen; k < nLen; k++) {
                            curr.appendChild(nChildren[k].cloneNode(true));
                        }
                    } else if (cLen > nLen) {
                        for (var l = cLen - 1; l >= nLen; l--) {
                            curr.removeChild(cChildren[l]);
                        }
                    }
                }

                function updateStats() {
                    loadXsl(function(xsl) {
                        var xmlHttp = new XMLHttpRequest();
                        xmlHttp.open("GET", window.location.href, true);
                        xmlHttp.setRequestHeader("Cache-Control", "no-cache");
                        xmlHttp.onload = function() {
                            if (xmlHttp.status === 200 && xmlHttp.responseXML) {
                                try {
                                    var xsltProcessor = new XSLTProcessor();
                                    xsltProcessor.importStylesheet(xsl);
                                    var resultDoc = xsltProcessor.transformToDocument(xmlHttp.responseXML);
                                    var next = resultDoc.getElementById("stat-table");
                                    var curr = document.getElementById("stat-table");
                                    if (next && curr) {
                                        morphNode(curr, next);
                                        return;
                                    }
                                } catch(e) {
                                    console.error("XSLT transform error:", e);
                                }
                            }
                        };
                        xmlHttp.send("");
                    });
                }

                var previewHls = null;
                var previewTimer = null;

                function showPreview(streamName, event) {
                    if (previewTimer) clearTimeout(previewTimer);
                    var container = document.getElementById("hover-preview-container");
                    var video = document.getElementById("hover-preview-video");
                    if (!container || !video) return;

                    var src = "/hls/" + streamName + ".m3u8";
                    container.style.display = "block";
                    container.style.left = (event.pageX + 15) + "px";
                    container.style.top = (event.pageY + 10) + "px";

                    if (video.getAttribute("data-current-src") === src) return;
                    video.setAttribute("data-current-src", src);

                    if (previewHls) {
                        previewHls.destroy();
                        previewHls = null;
                    }

                    if (window.Hls && Hls.isSupported()) {
                        previewHls = new Hls({ maxBufferLength: 1, liveSyncDurationCount: 1 });
                        previewHls.loadSource(src);
                        previewHls.attachMedia(video);
                        previewHls.on(Hls.Events.MANIFEST_PARSED, function() {
                            video.play().catch(function(){});
                        });
                    } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
                        video.src = src;
                        video.play().catch(function(){});
                    }
                }

                function movePreview(event) {
                    var container = document.getElementById("hover-preview-container");
                    if (container && container.style.display === "block") {
                        container.style.left = (event.pageX + 15) + "px";
                        container.style.top = (event.pageY + 10) + "px";
                    }
                }

                function hidePreview() {
                    previewTimer = setTimeout(function() {
                        var container = document.getElementById("hover-preview-container");
                        var video = document.getElementById("hover-preview-video");
                        if (container) container.style.display = "none";
                        if (video) {
                            video.pause();
                            video.removeAttribute("data-current-src");
                        }
                        if (previewHls) {
                            previewHls.destroy();
                            previewHls = null;
                        }
                    }, 100);
                }

                function setRefresh(sec) {
                    if (refreshTimer) { clearInterval(refreshTimer); refreshTimer = null; }
                    if (sec > 0) refreshTimer = setInterval(updateStats, sec * 1000);
                }

                window.addEventListener("DOMContentLoaded", function() {
                    setRefresh(2);
                });
                ]]>
            </script>
            <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
        </head>
        <body style="font-family:sans-serif; margin:15px;">
            <!-- Floating Live Preview Popup -->
            <div id="hover-preview-container" style="display:none; position:absolute; z-index:9999; background:#000; border:1px solid #333; box-shadow:2px 2px 8px rgba(0,0,0,0.5); width:320px; height:180px; overflow:hidden;">
                <div style="background:#222; color:#fff; font-size:11px; padding:2px 6px; font-weight:bold;">LIVE PREVIEW</div>
                <video id="hover-preview-video" muted="muted" autoplay="autoplay" playsinline="playsinline" style="width:100%; height:156px; background:#000; object-fit:contain;"></video>
            </div>

            <div style="margin-bottom: 8px; font-size: 13px;">
                <b>RTMP statistics</b>
                &#160;|&#160;
                Auto refresh:
                <select onchange="setRefresh(parseInt(this.value, 10))" style="font-size:12px;">
                    <option value="1">1s</option>
                    <option value="2" selected="selected">2s</option>
                    <option value="5">5s</option>
                    <option value="0">off</option>
                </select>
                &#160;
                <a href="" onclick="updateStats(); return false;">[refresh now]</a>
            </div>

            <div id="stat-table">
                <xsl:apply-templates select="rtmp"/>
            </div>

            <hr/>
            <span style="font-size:11px; color:#666;">
                Generated by <a href='https://github.com/arut/nginx-rtmp-module'>nginx-rtmp-module</a>&#160;<xsl:value-of select="/rtmp/nginx_rtmp_version"/>,
                <a href="http://nginx.org">nginx</a>&#160;<xsl:value-of select="/rtmp/nginx_version"/>,
                pid <xsl:value-of select="/rtmp/pid"/>,
                built <xsl:value-of select="/rtmp/built"/>&#160;<xsl:value-of select="/rtmp/compiler"/>
            </span>
        </body>
    </html>
</xsl:template>

<xsl:template match="rtmp">
    <table cellspacing="1" cellpadding="5">
        <tr bgcolor="#999999">
            <th>RTMP</th>
            <th>#clients</th>
            <th colspan="4">Video</th>
            <th colspan="4">Audio</th>
            <th>In bytes</th>
            <th>Out bytes</th>
            <th>In bits/s</th>
            <th>Out bits/s</th>
            <th>State</th>
            <th>Time</th>
        </tr>
        <tr>
            <td colspan="2">Accepted: <xsl:value-of select="naccepted"/></td>
            <th bgcolor="#999999">codec</th>
            <th bgcolor="#999999">bits/s</th>
            <th bgcolor="#999999">size</th>
            <th bgcolor="#999999">fps</th>
            <th bgcolor="#999999">codec</th>
            <th bgcolor="#999999">bits/s</th>
            <th bgcolor="#999999">freq</th>
            <th bgcolor="#999999">chan</th>
            <td>
                <xsl:call-template name="showsize">
                    <xsl:with-param name="size" select="bytes_in"/>
                </xsl:call-template>
            </td>
            <td>
                <xsl:call-template name="showsize">
                    <xsl:with-param name="size" select="bytes_out"/>
                </xsl:call-template>
            </td>
            <td>
                <xsl:call-template name="showsize">
                    <xsl:with-param name="size" select="bw_in"/>
                    <xsl:with-param name="bits" select="1"/>
                    <xsl:with-param name="persec" select="1"/>
                </xsl:call-template>
            </td>
            <td>
                <xsl:call-template name="showsize">
                    <xsl:with-param name="size" select="bw_out"/>
                    <xsl:with-param name="bits" select="1"/>
                    <xsl:with-param name="persec" select="1"/>
                </xsl:call-template>
            </td>
            <td/>
            <td>
                <xsl:call-template name="showtime">
                    <xsl:with-param name="time" select="/rtmp/uptime * 1000"/>
                </xsl:call-template>
            </td>
        </tr>
        <xsl:apply-templates select="server"/>
    </table>
</xsl:template>

<xsl:template match="server">
    <xsl:apply-templates select="application"/>
</xsl:template>

<xsl:template match="application">
    <tr bgcolor="#999999">
        <td>
            <b><xsl:value-of select="name"/></b>
        </td>
    </tr>
    <xsl:apply-templates select="live"/>
    <xsl:apply-templates select="play"/>
</xsl:template>

<xsl:template match="live">
    <tr bgcolor="#aaaaaa">
        <td>
            <i>live streams</i>
        </td>
        <td align="middle">
            <xsl:value-of select="nclients"/>
        </td>
    </tr>
    <xsl:apply-templates select="stream"/>
</xsl:template>

<xsl:template match="play">
    <tr bgcolor="#aaaaaa">
        <td>
            <i>vod streams</i>
        </td>
        <td align="middle">
            <xsl:value-of select="nclients"/>
        </td>
    </tr>
    <xsl:apply-templates select="stream"/>
</xsl:template>

<xsl:template match="stream">
    <tr valign="top">
        <xsl:attribute name="bgcolor">
            <xsl:choose>
                <xsl:when test="active">#cccccc</xsl:when>
                <xsl:otherwise>#dddddd</xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <td>
            <a href="">
                <xsl:attribute name="onclick">
                    var d=document.getElementById('<xsl:value-of select="../../name"/>-<xsl:value-of select="name"/>');
                    d.style.display=d.style.display=='none'?'':'none';
                    return false;
                </xsl:attribute>
                <xsl:if test="active">
                    <xsl:attribute name="onmouseenter">
                        showPreview('<xsl:value-of select="name"/>', event);
                    </xsl:attribute>
                    <xsl:attribute name="onmousemove">
                        movePreview(event);
                    </xsl:attribute>
                    <xsl:attribute name="onmouseleave">
                        hidePreview();
                    </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="name"/>
                <xsl:if test="string-length(name) = 0">
                    [EMPTY]
                </xsl:if>
            </a>
        </td>
        <td align="middle"> <xsl:value-of select="nclients"/> </td>
        <td>
            <xsl:value-of select="meta/video/codec"/>&#160;<xsl:value-of select="meta/video/profile"/>&#160;<xsl:value-of select="meta/video/level"/>
        </td>
        <td>
            <xsl:call-template name="showsize">
                <xsl:with-param name="size" select="bw_video"/>
                <xsl:with-param name="bits" select="1"/>
                <xsl:with-param name="persec" select="1"/>
            </xsl:call-template>
        </td>
        <td>
            <xsl:apply-templates select="meta/video/width"/>
        </td>
        <td>
            <xsl:value-of select="meta/video/frame_rate"/>
        </td>
        <td>
            <xsl:value-of select="meta/audio/codec"/>&#160;<xsl:value-of select="meta/audio/profile"/>
        </td>
        <td>
            <xsl:call-template name="showsize">
                <xsl:with-param name="size" select="bw_audio"/>
                <xsl:with-param name="bits" select="1"/>
                <xsl:with-param name="persec" select="1"/>
            </xsl:call-template>
        </td>
        <td>
            <xsl:apply-templates select="meta/audio/sample_rate"/>
        </td>
        <td>
            <xsl:value-of select="meta/audio/channels"/>
        </td>
        <td>
            <xsl:call-template name="showsize">
               <xsl:with-param name="size" select="bytes_in"/>
           </xsl:call-template>
        </td>
        <td>
            <xsl:call-template name="showsize">
                <xsl:with-param name="size" select="bytes_out"/>
            </xsl:call-template>
        </td>
        <td>
            <xsl:call-template name="showsize">
                <xsl:with-param name="size" select="bw_in"/>
                <xsl:with-param name="bits" select="1"/>
                <xsl:with-param name="persec" select="1"/>
            </xsl:call-template>
        </td>
        <td>
            <xsl:call-template name="showsize">
                <xsl:with-param name="size" select="bw_out"/>
                <xsl:with-param name="bits" select="1"/>
                <xsl:with-param name="persec" select="1"/>
            </xsl:call-template>
        </td>
        <td><xsl:call-template name="streamstate"/></td>
        <td>
            <xsl:call-template name="showtime">
               <xsl:with-param name="time" select="time"/>
            </xsl:call-template>
        </td>
    </tr>
    <tr style="display:none">
        <xsl:attribute name="id">
            <xsl:value-of select="../../name"/>-<xsl:value-of select="name"/>
        </xsl:attribute>
        <td colspan="16" ngcolor="#eeeeee">
            <table cellspacing="1" cellpadding="5">
                <tr>
                    <th>Id</th>
                    <th>State</th>
                    <th>Address</th>
                    <th>Flash version</th>
                    <th>Page URL</th>
                    <th>SWF URL</th>
                    <th>Dropped</th>
                    <th>Timestamp</th>
                    <th>A-V</th>
                    <th>Time</th>
                </tr>
                <xsl:apply-templates select="client"/>
            </table>
        </td>
    </tr>
</xsl:template>

<xsl:template name="showtime">
    <xsl:param name="time"/>

    <xsl:if test="$time &gt; 0">
        <xsl:variable name="sec">
            <xsl:value-of select="floor($time div 1000)"/>
        </xsl:variable>

        <xsl:if test="$sec &gt;= 86400">
            <xsl:value-of select="floor($sec div 86400)"/>d
        </xsl:if>

        <xsl:if test="$sec &gt;= 3600">
            <xsl:value-of select="(floor($sec div 3600)) mod 24"/>h
        </xsl:if>

        <xsl:if test="$sec &gt;= 60">
            <xsl:value-of select="(floor($sec div 60)) mod 60"/>m
        </xsl:if>

        <xsl:value-of select="$sec mod 60"/>s
    </xsl:if>
</xsl:template>

<xsl:template name="showsize">
    <xsl:param name="size"/>
    <xsl:param name="bits" select="0" />
    <xsl:param name="persec" select="0" />
    <xsl:variable name="sizen">
        <xsl:value-of select="floor($size div 1024)"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$sizen &gt;= 1073741824">
            <xsl:value-of select="format-number($sizen div 1073741824,'#.###')"/> T</xsl:when>

        <xsl:when test="$sizen &gt;= 1048576">
            <xsl:value-of select="format-number($sizen div 1048576,'#.###')"/> G</xsl:when>

        <xsl:when test="$sizen &gt;= 1024">
            <xsl:value-of select="format-number($sizen div 1024,'#.##')"/> M</xsl:when>
        <xsl:when test="$sizen &gt;= 0">
            <xsl:value-of select="$sizen"/> K</xsl:when>
    </xsl:choose>
    <xsl:if test="string-length($size) &gt; 0">
        <xsl:choose>
            <xsl:when test="$bits = 1">b</xsl:when>
            <xsl:otherwise>B</xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$persec = 1">/s</xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template name="streamstate">
    <xsl:choose>
        <xsl:when test="active"><span style="color:#008000; font-weight:bold;">active</span></xsl:when>
        <xsl:otherwise><span style="color:#888888;">idle</span></xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template name="clientstate">
    <xsl:choose>
        <xsl:when test="publishing">publishing</xsl:when>
        <xsl:otherwise>playing</xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template match="client">
    <tr>
        <xsl:attribute name="bgcolor">
            <xsl:choose>
                <xsl:when test="publishing">#cccccc</xsl:when>
                <xsl:otherwise>#eeeeee</xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <td><xsl:value-of select="id"/></td>
        <td><xsl:call-template name="clientstate"/></td>
        <td>
            <a target="_blank">
                <xsl:attribute name="href">
                    http://apps.db.ripe.net/search/query.html&#63;searchtext=<xsl:value-of select="address"/>
                </xsl:attribute>
                <xsl:attribute name="title">whois</xsl:attribute>
                <xsl:value-of select="address"/>
            </a>
        </td>
        <td><xsl:value-of select="flashver"/></td>
        <td>
            <a target="_blank">
                <xsl:attribute name="href">
                    <xsl:value-of select="pageurl"/>
                </xsl:attribute>
                <xsl:value-of select="pageurl"/>
            </a>
        </td>
        <td><xsl:value-of select="swfurl"/></td>
        <td>
            <xsl:choose>
                <xsl:when test="dropped &gt; 0">
                    <span style="color:#c00; font-weight:bold;"><xsl:value-of select="dropped"/></span>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="dropped"/>
                </xsl:otherwise>
            </xsl:choose>
        </td>
        <td><xsl:value-of select="timestamp"/></td>
        <td><xsl:value-of select="avsync"/></td>
        <td>
            <xsl:call-template name="showtime">
               <xsl:with-param name="time" select="time"/>
            </xsl:call-template>
        </td>
    </tr>
</xsl:template>

<xsl:template match="publishing">
    publishing
</xsl:template>

<xsl:template match="active">
    active
</xsl:template>

<xsl:template match="width">
    <xsl:value-of select="."/>x<xsl:value-of select="../height"/>
</xsl:template>

</xsl:stylesheet>