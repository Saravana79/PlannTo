(function (e) {
	e.fn.layerSlider = function (n) {
		if ((typeof n).match("object|undefined")) {
			return this.each(function (e) {
				new t(this, n)
			})
		} else {
			if (n == "data") {
				var r = e(this).data("LayerSlider").g;
				if (r) {
					return r
				}
			} else {
				return this.each(function (t) {
					var r = e(this).data("LayerSlider");
					if (r) {
						if (!r.g.isAnimating) {
							if (typeof n == "number") {
								if (n > 0 && n < r.g.layersNum + 1 && n != r.g.curLayerIndex) {
									r.change(n)
								}
							} else {
								switch (n) {
								case "prev":
									r.o.cbPrev();
									r.prev("clicked");
									break;
								case "next":
									r.o.cbNext();
									r.next("clicked");
									break;
								case "start":
									if (!r.g.autoSlideshow) {
										r.o.cbStart();
										r.g.originalAutoSlideshow = true;
										r.start()
									}
									break;
								case "debug":
									r.d.show();
									break
								}
							}
						}
						if ((r.g.autoSlideshow || !r.g.autoSlideshow && r.g.originalAutoSlideshow) && n == "stop") {
							r.o.cbStop();
							r.g.originalAutoSlideshow = false;
							r.g.curLayer.find('iframe[src*="www.youtu"], iframe[src*="player.vimeo"]').each(function () {
								clearTimeout(e(this).data("videoTimer"))
							});
							r.stop()
						}
					}
				})
			}
		}
	};
	var t = function (n, r) {
		var i = this;
		i.$el = e(n).addClass("ls-container");
		i.$el.data("LayerSlider", i);
		i.load = function () {
			i.o = e.extend({},
			t.options, r);
			i.g = e.extend({},
			t.global);
			i.debug();
			if (e("html").find('meta[content*="WordPress"]').length) {
				i.g.wpVersion = e("html").find('meta[content*="WordPress"]').attr("content").split("WordPress")[1]
			}
			if (e("html").find('script[src*="layerslider"]').length) {
				if (e("html").find('script[src*="layerslider"]').attr("src").indexOf("?") != -1) {
					i.g.lswpVersion = e("html").find('script[src*="layerslider"]').attr("src").split("?")[1].split("=")[1]
				}
			}
			i.d.add("This site is running LayerSlider", true);
			i.d.add("JS version: " + i.g.version);
			if (i.g.lswpVersion) {
				i.d.add("WP version: " + i.g.lswpVersion)
			}
			if (i.g.wpVersion) {
				i.d.add("WordPress version: " + i.g.wpVersion)
			}
			i.d.add("jQuery version: " + e().jquery);
			i.d.add("Init code:", true);
			for (var s in i.o) {
				i.d.add(s + ": " + i.o[s])
			}
			if (!i.o.skin || i.o.skin == "" || !i.o.skinsPath || i.o.skinsPath == "") {
				i.d.add("Loading without skin. Possibilities: mistyped skin and / or skinsPath.");
				i.init()
			} else {
				i.d.add("Trying to load with skin: " + i.o.skin, true);
				e(n).addClass("ls-" + i.o.skin);
				var o = i.o.skinsPath + i.o.skin + "/skin.css";
				cssContainer = e("head");
				if (!e("head").length) {
					cssContainer = e("body")
				}
				if (document.createStyleSheet) {
					document.createStyleSheet(o);
					var u = e('link[href="' + o + '"]')
				} else {
					var u = e('<link rel="stylesheet" href="' + o + '" type="text/css" />').appendTo(cssContainer)
				}
				u.load(function () {
					if (!i.g.loaded) {
						i.d.add("curSkin.load(); fired");
						i.g.loaded = true;
						i.init()
					}
				});
				e(window).load(function () {
					if (!i.g.loaded) {
						i.d.add("$(window).load(); fired");
						i.g.loaded = true;
						i.init()
					}
				});
				setTimeout(function () {
					if (!i.g.loaded) {
						i.d.add("Fallback mode: Neither curSkin.load(); or $(window).load(); were fired");
						i.g.loaded = true;
						i.init()
					}
				},
				2e3)
			}
		};
		i.init = function () {
			i.d.add("FUNCTION ls.init();", true);
			i.g.sliderWidth = function () {
				return e(n).width()
			};
			i.g.sliderHeight = function () {
				return e(n).height()
			};
			if (e(n).find(".ls-layer").length == 1) {
				i.o.autoStart = false;
				i.o.navPrevNext = false;
				i.o.navStartStop = false;
				i.o.navButtons = false;
				i.o.loops = 0;
				i.o.forceLoopNum = false;
				i.o.autoPauseSlideshow = true;
				i.o.firstLayer = 1;
				i.o.thumbnailNavigation = "disabled"
			}
			i.d.add("Number of layers found: " + e(n).find(".ls-layer").length);
			if (i.o.width) {
				i.g.sliderOriginalWidthRU = i.g.sliderOriginalWidth = "" + i.o.width
			} else {
				i.g.sliderOriginalWidthRU = i.g.sliderOriginalWidth = e(n)[0].style.width
			}
			i.d.add("sliderOriginalWidth: " + i.g.sliderOriginalWidth);
			if (i.o.height) {
				i.g.sliderOriginalHeight = "" + i.o.height
			} else {
				i.g.sliderOriginalHeight = e(n)[0].style.height
			}
			i.d.add("sliderOriginalHeight: " + i.g.sliderOriginalHeight);
			if (i.g.sliderOriginalWidth.indexOf("%") == -1 && i.g.sliderOriginalWidth.indexOf("px") == -1) {
				i.g.sliderOriginalWidth += "px"
			}
			if (i.g.sliderOriginalHeight.indexOf("%") == -1 && i.g.sliderOriginalHeight.indexOf("px") == -1) {
				i.g.sliderOriginalHeight += "px"
			}
			if (i.o.responsive && i.g.sliderOriginalWidth.indexOf("px") != -1 && i.g.sliderOriginalHeight.indexOf("px") != -1) {
				i.g.responsiveMode = true
			} else {
				i.g.responsiveMode = false
			}
			e(n).find('*[class*="ls-s"], *[class*="ls-bg"]').each(function () {
				if (!e(this).parent().hasClass("ls-layer")) {
					e(this).insertBefore(e(this).parent())
				}
			});
			e(n).find(".ls-layer").each(function () {
				e(this).children(':not([class*="ls-"])').each(function () {
					e(this).remove()
				})
			});
			e(n).find('.ls-layer, *[class*="ls-s"]').each(function () {
				if (e(this).hasClass("ls-layer")) {
					i.d.add("LAYER " + (e(this).index() + 1) + " properties:", true)
				} else {
					i.d.add("  <span>SUBLAYER " + (e(this).index() + 1) + ", type: " + e(this).prev().prop("tagName") + "</span>", true);
					i.d.addFunction(e(this))
				}
				if (e(this).attr("rel") || e(this).attr("style")) {
					if (e(this).attr("rel")) {
						var t = e(this).attr("rel").toLowerCase().split(";")
					} else {
						var t = e(this).attr("style").toLowerCase().split(";")
					}
					for (x = 0; x < t.length; x++) {
						param = t[x].split(":");
						if (param[0].indexOf("easing") != -1) {
							param[1] = i.ieEasing(param[1])
						}
						var n = "";
						if (param[2]) {
							n = ":" + e.trim(param[2])
						}
						if (param[0] != " " && param[0] != "") {
							e(this).data(e.trim(param[0]), e.trim(param[1]) + n);
							i.d.add(e.trim(param[0]) + ": " + e.trim(param[1]) + n)
						}
					}
				}
				var r = e(this);
				r.data("originalLeft", r[0].style.left);
				r.data("originalTop", r[0].style.top);
				if (e(this).is("a") && e(this).children().length > 0) {
					r = e(this).children()
				}
				r.data("originalWidth", r.width());
				r.data("originalHeight", r.height());
				r.data("originalPaddingLeft", r.css("padding-left"));
				r.data("originalPaddingRight", r.css("padding-right"));
				r.data("originalPaddingTop", r.css("padding-top"));
				r.data("originalPaddingBottom", r.css("padding-bottom"));
				if (r.css("border-left-width").indexOf("px") == -1) {
					r.data("originalBorderLeft", r[0].style.borderLeftWidth)
				} else {
					r.data("originalBorderLeft", r.css("border-left-width"))
				}
				if (r.css("border-right-width").indexOf("px") == -1) {
					r.data("originalBorderRight", r[0].style.borderRightWidth)
				} else {
					r.data("originalBorderRight", r.css("border-right-width"))
				}
				if (r.css("border-top-width").indexOf("px") == -1) {
					r.data("originalBorderTop", r[0].style.borderTopWidth)
				} else {
					r.data("originalBorderTop", r.css("border-top-width"))
				}
				if (r.css("border-bottom-width").indexOf("px") == -1) {
					r.data("originalBorderBottom", r[0].style.borderBottomWidth)
				} else {
					r.data("originalBorderBottom", r.css("border-bottom-width"))
				}
				r.data("originalFontSize", r.css("font-size"));
				r.data("originalLineHeight", r.css("line-height"))
			});
			if (document.location.hash) {
				for (var t = 0; t < e(n).find(".ls-layer").length; t++) {
					if (e(n).find(".ls-layer").eq(t).data("deeplink") == document.location.hash.split("#")[1]) {
						i.o.firstLayer = t + 1
					}
				}
			}
			e(n).find('*[class*="ls-linkto-"]').each(function () {
				var t = e(this).attr("class").split(" ");
				for (var r = 0; r < t.length; r++) {
					if (t[r].indexOf("ls-linkto-") != -1) {
						var i = parseInt(t[r].split("ls-linkto-")[1]);
						e(this).css({
							cursor: "pointer"
						}).click(function (t) {
							t.preventDefault();
							e(n).layerSlider(i)
						})
					}
				}
			});
			i.g.layersNum = e(n).find(".ls-layer").length;
			if (i.o.randomSlideshow && i.g.layersNum > 2) {
				i.o.firstLayer == "random";
				i.o.twoWaySlideshow = false
			} else {
				i.o.randomSlideshow = false
			}
			if (i.o.firstLayer == "random") {
				i.o.firstLayer = Math.floor(Math.random() * i.g.layersNum + 1)
			}
			i.o.firstLayer = i.o.firstLayer < i.g.layersNum + 1 ? i.o.firstLayer: 1;
			i.o.firstLayer = i.o.firstLayer < 1 ? 1 : i.o.firstLayer;
			i.g.nextLoop = 1;
			if (i.o.animateFirstLayer) {
				i.g.nextLoop = 0
			}
			e(n).find('iframe[src*="www.youtu"]').each(function () {
				if (e(this).parent('[class*="ls-s"]')) {
					var t = e(this);
					e.getJSON("http://gdata.youtube.com/feeds/api/videos/" + e(this).attr("src").split("embed/")[1].split("?")[0] + "?v=2&alt=json&callback=?", function (e) {
						t.data("videoDuration", parseInt(e["entry"]["media$group"]["yt$duration"]["seconds"]) * 1e3)
					});
					var n = e("<div>").addClass("ls-vpcontainer").appendTo(e(this).parent());
					e("<img>").appendTo(n).addClass("ls-videopreview").attr("src", "http://img.youtube.com/vi/" + e(this).attr("src").split("embed/")[1].split("?")[0] + "/" + i.o.youtubePreview);
					e("<div>").appendTo(n).addClass("ls-playvideo");
					e(this).parent().css({
						width: e(this).width(),
						height: e(this).height()
					}).click(function () {
						i.g.isAnimating = true;
						if (i.g.paused) {
							if (i.o.autoPauseSlideshow != false) {
								i.g.paused = false
							}
							i.g.originalAutoSlideshow = true
						} else {
							i.g.originalAutoSlideshow = i.g.autoSlideshow
						}
						if (i.o.autoPauseSlideshow != false) {
							i.stop()
						}
						i.g.pausedByVideo = true;
						e(this).find("iframe").attr("src", e(this).find("iframe").data("videoSrc"));
						e(this).find(".ls-vpcontainer").delay(i.g.v.d).fadeOut(i.g.v.fo, function () {
							if (i.o.autoPauseSlideshow == "auto" && i.g.originalAutoSlideshow == true) {
								var e = setTimeout(function () {
									i.start()
								},
								t.data("videoDuration") - i.g.v.d);
								t.data("videoTimer", e)
							}
							i.g.isAnimating = false
						})
					});
					var r = "&";
					if (e(this).attr("src").indexOf("?") == -1) {
						r = "?"
					}
					e(this).data("videoSrc", e(this).attr("src") + r + "autoplay=1");
					e(this).data("originalWidth", e(this).attr("width"));
					e(this).data("originalHeight", e(this).attr("height"));
					e(this).attr("src", "")
				}
			});
			e(n).find('iframe[src*="player.vimeo"]').each(function () {
				if (e(this).parent('[class*="ls-s"]')) {
					var t = e(this);
					var n = e("<div>").addClass("ls-vpcontainer").appendTo(e(this).parent());
					e.getJSON("http://vimeo.com/api/v2/video/" + e(this).attr("src").split("video/")[1].split("?")[0] + ".json?callback=?", function (r) {
						e("<img>").appendTo(n).addClass("ls-videopreview").attr("src", r[0]["thumbnail_large"]);
						t.data("videoDuration", parseInt(r[0]["duration"]) * 1e3);
						e("<div>").appendTo(n).addClass("ls-playvideo")
					});
					e(this).parent().css({
						width: e(this).width(),
						height: e(this).height()
					}).click(function () {
						i.g.isAnimating = true;
						if (i.g.paused) {
							if (i.o.autoPauseSlideshow != false) {
								i.g.paused = false
							}
							i.g.originalAutoSlideshow = true
						} else {
							i.g.originalAutoSlideshow = i.g.autoSlideshow
						}
						if (i.o.autoPauseSlideshow != false) {
							i.stop()
						}
						i.g.pausedByVideo = true;
						e(this).find("iframe").attr("src", e(this).find("iframe").data("videoSrc"));
						e(this).find(".ls-vpcontainer").delay(i.g.v.d).fadeOut(i.g.v.fo, function () {
							if (i.o.autoPauseSlideshow == "auto" && i.g.originalAutoSlideshow == true) {
								var e = setTimeout(function () {
									i.start()
								},
								t.data("videoDuration") - i.g.v.d);
								t.data("videoTimer", e)
							}
							i.g.isAnimating = false
						})
					});
					var r = "&";
					if (e(this).attr("src").indexOf("?") == -1) {
						r = "?"
					}
					e(this).data("videoSrc", e(this).attr("src") + r + "autoplay=1");
					e(this).data("originalWidth", e(this).attr("width"));
					e(this).data("originalHeight", e(this).attr("height"));
					e(this).attr("src", "")
				}
			});
			if (i.o.animateFirstLayer) {
				i.o.firstLayer = i.o.firstLayer - 1 == 0 ? i.g.layersNum: i.o.firstLayer - 1
			}
			i.g.curLayerIndex = i.o.firstLayer;
			i.g.curLayer = e(n).find(".ls-layer:eq(" + (i.g.curLayerIndex - 1) + ")");
			e(n).find(".ls-layer").wrapAll('<div class="ls-inner"></div>');
			if (e(n).css("position") == "static") {
				e(n).css("position", "relative")
			}
			e(n).find(".ls-inner").css({
				backgroundColor: i.o.globalBGColor
			});
			if (i.o.globalBGImage) {
				e(n).find(".ls-inner").css({
					backgroundImage: "url(" + i.o.globalBGImage + ")"
				})
			}
			if (i.o.navPrevNext) {
				e('<a class="ls-nav-prev" href="#" />').click(function (t) {
					t.preventDefault();
					e(n).layerSlider("prev")
				}).appendTo(e(n));
				e('<a class="ls-nav-next" href="#" />').click(function (t) {
					t.preventDefault();
					e(n).layerSlider("next")
				}).appendTo(e(n));
				if (i.o.hoverPrevNext) {
					e(n).find(".ls-nav-prev, .ls-nav-next").css({
						display: "none"
					});
					e(n).hover(function () {
						e(n).find(".ls-nav-prev, .ls-nav-next").stop(true, true).fadeIn(300)
					},
					function () {
						e(n).find(".ls-nav-prev, .ls-nav-next").stop(true, true).fadeOut(300)
					})
				}
			}
			if (i.o.navStartStop || i.o.navButtons) {
				var r = e('<div class="ls-bottom-nav-wrapper" />').appendTo(e(n));
				if (i.o.thumbnailNavigation == "always") {
					r.addClass("ls-above-thumbnails")
				}
				if (i.o.navButtons && i.o.thumbnailNavigation != "always") {
					e('<span class="ls-bottom-slidebuttons" />').appendTo(e(n).find(".ls-bottom-nav-wrapper"));
					if (i.o.thumbnailNavigation == "hover") {
						var s = e('<div class="ls-thumbnail-hover"><div class="ls-thumbnail-hover-inner"><div class="ls-thumbnail-hover-bg"></div><div class="ls-thumbnail-hover-img"><img></div><span></span></div></div>').appendTo(e(n).find(".ls-bottom-slidebuttons"))
					}
					for (x = 1; x < i.g.layersNum + 1; x++) {
						var o = e('<a href="#" />').appendTo(e(n).find(".ls-bottom-slidebuttons")).click(function (t) {
							t.preventDefault();
							e(n).layerSlider(e(this).index() + 1)
						});
						if (i.o.thumbnailNavigation == "hover") {
							e(n).find(".ls-thumbnail-hover, .ls-thumbnail-hover-img").css({
								width: i.o.tnWidth,
								height: i.o.tnHeight
							});
							var u = e(n).find(".ls-thumbnail-hover");
							var a = u.find("img").css({
								height: i.o.tnHeight
							});
							var f = e(n).find(".ls-thumbnail-hover-inner").css({
								visibility: "hidden",
								display: "block"
							});
							o.hover(function () {
								var t = e(n).find(".ls-layer").eq(e(this).index());
								if (t.find(".ls-tn").length) {
									var r = t.find(".ls-tn").attr("src")
								} else if (t.find(".ls-videopreview").length) {
									var r = t.find(".ls-videopreview").attr("src")
								} else if (t.find(".ls-bg").length) {
									var r = t.find(".ls-bg").attr("src")
								} else {
									var r = i.o.skinsPath + i.o.skin + "/nothumb.png"
								}
								e(n).find(".ls-thumbnail-hover-img").css({
									left: parseInt(u.css("padding-left")),
									top: parseInt(u.css("padding-top"))
								});
								a.load(function () {
									if (e(this).width() == 0) {
										a.css({
											position: "relative",
											margin: "0 auto",
											left: "auto"
										})
									} else {
										a.css({
											position: "absolute",
											marginLeft: -e(this).width() / 2,
											left: "50%"
										})
									}
								}).attr("src", r);
								u.css({
									display: "block"
								}).stop().animate({
									left: e(this).position().left + (e(this).width() - u.outerWidth()) / 2
								},
								250, "easeInOutQuad");
								f.css({
									display: "none",
									visibility: "visible"
								}).stop().fadeIn(250)
							},
							function () {
								f.stop().fadeOut(250, function () {
									u.css({
										visibility: "hidden",
										display: "block"
									})
								})
							})
						}
					}
					if (i.o.thumbnailNavigation == "hover") {
						s.appendTo(e(n).find(".ls-bottom-slidebuttons"))
					}
					e(n).find(".ls-bottom-slidebuttons a:eq(" + (i.o.firstLayer - 1) + ")").addClass("ls-nav-active")
				}
				if (i.o.navStartStop) {
					var l = e('<a class="ls-nav-start" href="#" />').click(function (t) {
						t.preventDefault();
						e(n).layerSlider("start")
					}).prependTo(e(n).find(".ls-bottom-nav-wrapper"));
					var c = e('<a class="ls-nav-stop" href="#" />').click(function (t) {
						t.preventDefault();
						e(n).layerSlider("stop")
					}).appendTo(e(n).find(".ls-bottom-nav-wrapper"))
				} else if (i.o.thumbnailNavigation != "always") {
					e('<span class="ls-nav-sides ls-nav-sideleft" />').prependTo(e(n).find(".ls-bottom-nav-wrapper"));
					e('<span class="ls-nav-sides ls-nav-sideright" />').appendTo(e(n).find(".ls-bottom-nav-wrapper"))
				}
				if (i.o.hoverBottomNav && i.o.thumbnailNavigation != "always") {
					r.css({
						display: "none"
					});
					e(n).hover(function () {
						r.stop(true, true).fadeIn(300)
					},
					function () {
						r.stop(true, true).fadeOut(300)
					})
				}
			}
			if (i.o.thumbnailNavigation == "always") {
				var h = e('<div class="ls-thumbnail-wrapper"></div>').appendTo(e(n));
				var s = e('<div class="ls-thumbnail"><div class="ls-thumbnail-inner"><div class="ls-thumbnail-slide-container"><div class="ls-thumbnail-slide"></div></div></div></div>').appendTo(h);
				i.g.thumbnails = e(n).find(".ls-thumbnail-slide-container").hover(function () {
					e(this).addClass("ls-thumbnail-slide-hover")
				},
				function () {
					e(this).removeClass("ls-thumbnail-slide-hover");
					i.scrollThumb()
				}).mousemove(function (t) {
					var n = parseInt(t.pageX - e(this).offset().left) / e(this).width() * (e(this).width() - e(this).find(".ls-thumbnail-slide").width());
					e(this).find(".ls-thumbnail-slide").stop().css({
						marginLeft: n
					})
				});
				e(n).find(".ls-layer").each(function () {
					var t = e(this).index() + 1;
					if (e(this).find(".ls-tn").length) {
						var r = e(this).find(".ls-tn").attr("src")
					} else if (e(this).find(".ls-videopreview").length) {
						var r = e(this).find(".ls-videopreview").attr("src")
					} else if (e(this).find(".ls-bg").length) {
						var r = e(this).find(".ls-bg").attr("src")
					}
					if (r) {
						var s = e('<a href="#" class="ls-thumb-' + t + '"><img src="' + r + '"></a>')
					} else {
						var s = e('<a href="#" class="ls-nothumb ls-thumb-' + t + '"><img src="' + i.o.skinsPath + i.o.skin + '/nothumb.png"></a>')
					}
					s.hover(function () {
						e(this).children().stop().fadeTo(300, i.o.tnActiveOpacity / 100)
					},
					function () {
						if (!e(this).children().hasClass("ls-thumb-active")) {
							e(this).children().stop().fadeTo(300, i.o.tnInactiveOpacity / 100)
						}
					}).appendTo(e(n).find(".ls-thumbnail-slide")).click(function (r) {
						r.preventDefault();
						e(n).layerSlider(t)
					})
				});
				if (l && c) {
					var p = e('<div class="ls-bottom-nav-wrapper ls-below-thumbnails"></div>').appendTo(e(n));
					l.clone().click(function (t) {
						t.preventDefault();
						e(n).layerSlider("start")
					}).appendTo(p);
					c.clone().click(function (t) {
						t.preventDefault();
						e(n).layerSlider("stop")
					}).appendTo(p)
				}
				if (i.o.hoverBottomNav) {
					h.css({
						visibility: "hidden"
					});
					var d = p.css("display") == "block" ? p: e(n).find(".ls-above-thumbnails");
					d.css({
						display: "none"
					});
					e(n).hover(function () {
						h.css({
							visibility: "visible",
							display: "none"
						}).stop(true, false).fadeIn(300);
						d.stop(true, true).fadeIn(300)
					},
					function () {
						h.stop(true, true).fadeOut(300, function () {
							e(this).css({
								visibility: "hidden",
								display: "block"
							})
						});
						d.stop(true, true).fadeOut(300)
					})
				}
			}
			var v = e('<div class="ls-shadow"></div>').appendTo(e(n));
			v.data("originalHeight", v.height());
			shadowTimer = 150;
			setTimeout(function () {
				if (e(n).find(".ls-shadow").css("display") == "block") {
					e("<img />").attr("src", i.o.skinsPath + i.o.skin + "/shadow.png").appendTo(e(n).find(".ls-shadow"))
				}
			},
			shadowTimer);
			if (i.o.keybNav && e(n).find(".ls-layer").length > 1) {
				e("body").bind("keydown", function (e) {
					if (!i.g.isAnimating) {
						if (e.which == 37) {
							i.o.cbPrev(i.g);
							i.prev("clicked")
						} else if (e.which == 39) {
							i.o.cbNext(i.g);
							i.next("clicked")
						}
					}
				})
			}
			if ("ontouchstart" in window && e(n).find(".ls-layer").length > 1 && i.o.touchNav) {
				e(n).bind("touchstart", function (e) {
					var t = e.touches ? e.touches: e.originalEvent.touches;
					if (t.length == 1) {
						i.g.touchStartX = i.g.touchEndX = t[0].clientX
					}
				});
				e(n).bind("touchmove", function (e) {
					var t = e.touches ? e.touches: e.originalEvent.touches;
					if (t.length == 1) {
						i.g.touchEndX = t[0].clientX
					}
					if (Math.abs(i.g.touchStartX - i.g.touchEndX) > 45) {
						e.preventDefault()
					}
				});
				e(n).bind("touchend", function (t) {
					if (Math.abs(i.g.touchStartX - i.g.touchEndX) > 45) {
						if (i.g.touchStartX - i.g.touchEndX > 0) {
							i.o.cbNext(i.g);
							e(n).layerSlider("next")
						} else {
							i.o.cbPrev(i.g);
							e(n).layerSlider("prev")
						}
					}
				})
			}
			if (i.o.pauseOnHover == true && e(n).find(".ls-layer").length > 1) {
				e(n).find(".ls-inner").hover(function () {
					i.o.cbPause(i.g);
					if (i.g.autoSlideshow) {
						i.g.paused = true;
						i.stop()
					}
				},
				function () {
					if (i.g.paused == true) {
						i.start();
						i.g.paused = false
					}
				})
			}
			i.resizeSlider();
			if (i.o.yourLogo) {
				i.g.yourLogo = e("<img>").addClass("ls-yourlogo").appendTo(e(n)).attr("style", i.o.yourLogoStyle).css({
					visibility: "hidden",
					display: "bock"
				}).load(function () {
					var t = 0;
					if (!i.g.yourLogo) {
						t = 1e3
					}
					setTimeout(function () {
						i.g.yourLogo.data("originalWidth", i.g.yourLogo.width());
						i.g.yourLogo.data("originalHeight", i.g.yourLogo.height());
						if (i.g.yourLogo.css("left") != "auto") {
							i.g.yourLogo.data("originalLeft", i.g.yourLogo[0].style.left)
						}
						if (i.g.yourLogo.css("right") != "auto") {
							i.g.yourLogo.data("originalRight", i.g.yourLogo[0].style.right)
						}
						if (i.g.yourLogo.css("top") != "auto") {
							i.g.yourLogo.data("originalTop", i.g.yourLogo[0].style.top)
						}
						if (i.g.yourLogo.css("bottom") != "auto") {
							i.g.yourLogo.data("originalBottom", i.g.yourLogo[0].style.bottom)
						}
						if (i.o.yourLogoLink != false) {
							e("<a>").appendTo(e(n)).attr("href", i.o.yourLogoLink).attr("target", i.o.yourLogoTarget).css({
								textDecoration: "none",
								outline: "none"
							}).append(i.g.yourLogo)
						}
						i.g.yourLogo.css({
							display: "none",
							visibility: "visible"
						});
						i.resizeYourLogo()
					},
					t)
				}).attr("src", i.o.yourLogo)
			}
			e(window).resize(function () {
				i.makeResponsive(i.g.curLayer, function () {
					return
				});
				if (i.g.yourLogo) {
					i.resizeYourLogo()
				}
			});
			i.g.showSlider = true;
			if (i.o.animateFirstLayer == true) {
				if (i.o.autoStart) {
					i.g.autoSlideshow = true;
					e(n).find(".ls-nav-start").addClass("ls-nav-start-active")
				} else {
					e(n).find(".ls-nav-stop").addClass("ls-nav-stop-active")
				}
				i.next()
			} else {
				i.imgPreload(i.g.curLayer, function () {
					i.g.curLayer.fadeIn(1e3, function () {
						e(this).addClass("ls-active");
						if (i.o.autoPlayVideos) {
							e(this).delay(e(this).data("delayin") + 25).queue(function () {
								e(this).find(".ls-videopreview").click();
								e(this).dequeue()
							})
						}
						i.g.curLayer.find(' > *[class*="ls-s"]').each(function () {
							if (e(this).data("showuntil") > 0) {
								i.sublayerShowUntil(e(this))
							}
						})
					});
					i.changeThumb(i.g.curLayerIndex);
					if (i.o.autoStart) {
						i.start()
					} else {
						e(n).find(".ls-nav-stop").addClass("ls-nav-stop-active")
					}
				})
			}
			i.o.cbInit(e(n))
		};
		i.start = function () {
			if (i.g.autoSlideshow) {
				if (i.g.prevNext == "prev" && i.o.twoWaySlideshow) {
					i.prev()
				} else {
					i.next()
				}
			} else {
				i.g.autoSlideshow = true;
				i.timer()
			}
			e(n).find(".ls-nav-start").addClass("ls-nav-start-active");
			e(n).find(".ls-nav-stop").removeClass("ls-nav-stop-active")
		};
		i.timer = function () {
			var t = e(n).find(".ls-active").data("slidedelay") ? parseInt(e(n).find(".ls-active").data("slidedelay")) : i.o.slideDelay;
			if (!i.o.animateFirstLayer && !e(n).find(".ls-active").data("slidedelay")) {
				var r = e(n).find(".ls-layer:eq(" + (i.o.firstLayer - 1) + ")").data("slidedelay");
				t = r ? r: i.o.slideDelay
			}
			clearTimeout(i.g.slideTimer);
			i.g.slideTimer = window.setTimeout(function () {
				i.start()
			},
			t)
		};
		i.stop = function () {
			if (!i.g.paused && !i.g.originalAutoSlideshow) {
				e(n).find(".ls-nav-stop").addClass("ls-nav-stop-active");
				e(n).find(".ls-nav-start").removeClass("ls-nav-start-active")
			}
			clearTimeout(i.g.slideTimer);
			i.g.autoSlideshow = false
		};
		i.ieEasing = function (t) {
			if (e.trim(t.toLowerCase()) == "swing" || e.trim(t.toLowerCase()) == "linear") {
				return t.toLowerCase()
			} else {
				return t.replace("easeinout", "easeInOut").replace("easein", "easeIn").replace("easeout", "easeOut").replace("quad", "Quad").replace("quart", "Quart").replace("cubic", "Cubic").replace("quint", "Quint").replace("sine", "Sine").replace("expo", "Expo").replace("circ", "Circ").replace("elastic", "Elastic").replace("back", "Back").replace("bounce", "Bounce")
			}
		};
		i.prev = function (e) {
			if (i.g.curLayerIndex < 2) {
				i.g.nextLoop += 1
			}
			if (i.g.nextLoop > i.o.loops && i.o.loops > 0 && !e) {
				i.g.nextLoop = 0;
				i.stop();
				if (i.o.forceLoopNum == false) {
					i.o.loops = 0
				}
			} else {
				var t = i.g.curLayerIndex < 2 ? i.g.layersNum: i.g.curLayerIndex - 1;
				i.g.prevNext = "prev";
				i.change(t, i.g.prevNext)
			}
		};
		i.next = function (e) {
			if (!i.o.randomSlideshow) {
				if (! (i.g.curLayerIndex < i.g.layersNum)) {
					i.g.nextLoop += 1
				}
				if (i.g.nextLoop > i.o.loops && i.o.loops > 0 && !e) {
					i.g.nextLoop = 0;
					i.stop();
					if (i.o.forceLoopNum == false) {
						i.o.loops = 0
					}
				} else {
					var t = i.g.curLayerIndex < i.g.layersNum ? i.g.curLayerIndex + 1 : 1;
					i.g.prevNext = "next";
					i.change(t, i.g.prevNext)
				}
			} else if (!e) {
				var t = i.g.curLayerIndex;
				var n = function () {
					t = Math.floor(Math.random() * i.g.layersNum) + 1;
					if (t == i.g.curLayerIndex) {
						n()
					} else {
						i.g.prevNext = "next";
						i.change(t, i.g.prevNext)
					}
				};
				n()
			} else if (e) {
				var t = i.g.curLayerIndex < i.g.layersNum ? i.g.curLayerIndex + 1 : 1;
				i.g.prevNext = "next";
				i.change(t, i.g.prevNext)
			}
		};
		i.change = function (t, r) {
			if (i.g.pausedByVideo == true) {
				i.g.pausedByVideo = false;
				i.g.autoSlideshow = i.g.originalAutoSlideshow;
				i.g.curLayer.find('iframe[src*="www.youtu"], iframe[src*="player.vimeo"]').each(function () {
					e(this).parent().find(".ls-vpcontainer").fadeIn(i.g.v.fi, function () {
						e(this).parent().find("iframe").attr("src", "")
					})
				})
			}
			e(n).find('iframe[src*="www.youtu"], iframe[src*="player.vimeo"]').each(function () {
				clearTimeout(e(this).data("videoTimer"))
			});
			clearTimeout(i.g.slideTimer);
			i.g.nextLayerIndex = t;
			i.g.nextLayer = e(n).find(".ls-layer:eq(" + (i.g.nextLayerIndex - 1) + ")");
			if (!r) {
				if (i.g.curLayerIndex < i.g.nextLayerIndex) {
					i.g.prevNext = "next"
				} else {
					i.g.prevNext = "prev"
				}
			}
			var s = 0;
			if (e(n).find('iframe[src*="www.youtu"], iframe[src*="player.vimeo"]').length > 0) {
				s = i.g.v.fi
			}
			setTimeout(function () {
				i.imgPreload(i.g.nextLayer, function () {
					i.animate()
				})
			},
			s)
		};
		i.imgPreload = function (t, n) {
			if (i.o.imgPreload) {
				var r = [];
				var s = 0;
				if (t.css("background-image") != "none" && t.css("background-image").indexOf("url") != -1) {
					var o = t.css("background-image");
					o = o.match(/url\((.*)\)/)[1].replace(/"/gi, "");
					r.push(o)
				}
				t.find("img").each(function () {
					r.push(e(this).attr("src"))
				});
				t.find("*").each(function () {
					if (e(this).css("background-image") != "none" && e(this).css("background-image").indexOf("url") != -1) {
						var t = e(this).css("background-image");
						t = t.match(/url\((.*)\)/)[1].replace(/"/gi, "");
						r.push(t)
					}
				});
				if (r.length == 0) {
					i.makeResponsive(t, n)
				} else {
					for (x = 0; x < r.length; x++) {
						e("<img>").load(function () {
							if (++s == r.length) {
								i.makeResponsive(t, n)
							}
						}).attr("src", r[x])
					}
				}
			} else {
				i.makeResponsive(t, n)
			}
		};
		i.makeResponsive = function (t, r, s) {
			if (!s) {
				t.css({
					visibility: "hidden",
					display: "block"
				})
			}
			i.resizeSlider();
			if (i.o.thumbnailNavigation == "always") {
				i.resizeThumb()
			}
			for (var o = 0; o < t.children().length; o++) {
				var u = t.children(":eq(" + o + ")");
				var a = u.data("originalLeft") ? u.data("originalLeft") : "0";
				var f = u.data("originalTop") ? u.data("originalTop") : "0";
				if (u.is("a") && u.children().length > 0) {
					u = u.children()
				}
				var l = u.data("originalWidth") ? parseInt(u.data("originalWidth")) * i.g.ratio: "auto";
				var c = u.data("originalHeight") ? parseInt(u.data("originalHeight")) * i.g.ratio: "auto";
				var h = u.data("originalPaddingLeft") ? parseInt(u.data("originalPaddingLeft")) * i.g.ratio: 0;
				var p = u.data("originalPaddingRight") ? parseInt(u.data("originalPaddingRight")) * i.g.ratio: 0;
				var d = u.data("originalPaddingTop") ? parseInt(u.data("originalPaddingTop")) * i.g.ratio: 0;
				var v = u.data("originalPaddingBottom") ? parseInt(u.data("originalPaddingBottom")) * i.g.ratio: 0;
				var m = u.data("originalBorderLeft") ? parseInt(u.data("originalBorderLeft")) * i.g.ratio: 0;
				var g = u.data("originalBorderRight") ? parseInt(u.data("originalBorderRight")) * i.g.ratio: 0;
				var y = u.data("originalBorderTop") ? parseInt(u.data("originalBorderTop")) * i.g.ratio: 0;
				var b = u.data("originalBorderBottom") ? parseInt(u.data("originalBorderBottom")) * i.g.ratio: 0;
				var w = u.data("originalFontSize");
				var E = u.data("originalLineHeight");
				if (i.g.responsiveMode || i.o.responsiveUnder > 0) {
					if (u.is("img")) {
						u.css({
							width: "auto",
							height: "auto"
						});
						l = u.width();
						c = u.height();
						u.css({
							width: u.width() * i.g.ratio,
							height: u.height() * i.g.ratio
						})
					}
					if (!u.is("img")) {
						u.css({
							width: l,
							height: c,
							"font-size": parseInt(w) * i.g.ratio + "px",
							"line-height": parseInt(E) * i.g.ratio + "px"
						})
					}
					if (u.is("div") && u.find("iframe").data("videoSrc")) {
						var S = u.find("iframe");
						S.attr("width", parseInt(S.data("originalWidth")) * i.g.ratio).attr("height", parseInt(S.data("originalHeight")) * i.g.ratio);
						u.css({
							width: parseInt(S.data("originalWidth")) * i.g.ratio,
							height: parseInt(S.data("originalHeight")) * i.g.ratio
						})
					}
					u.css({
						padding: d + "px " + p + "px " + v + "px " + h + "px ",
						borderLeftWidth: m + "px",
						borderRightWidth: g + "px",
						borderTopWidth: y + "px",
						borderBottomWidth: b + "px"
					})
				}
				if (!u.hasClass("ls-bg")) {
					var x = u;
					if (u.parent().is("a")) {
						u = u.parent()
					}
					var T = i.o.sublayerContainer > 0 ? (i.g.sliderWidth() - i.o.sublayerContainer) / 2 : 0;
					T = T < 0 ? 0 : T;
					if (a.indexOf("%") != -1) {
						u.css({
							left: i.g.sliderWidth() / 100 * parseInt(a) - x.width() / 2 - h - m
						})
					} else if (T > 0 || i.g.responsiveMode || i.o.responsiveUnder > 0) {
						u.css({
							left: T + parseInt(a) * i.g.ratio
						})
					}
					if (f.indexOf("%") != -1) {
						u.css({
							top: i.g.sliderHeight() / 100 * parseInt(f) - x.height() / 2 - d - y
						})
					} else if (i.g.responsiveMode || i.o.responsiveUnder > 0) {
						u.css({
							top: parseInt(f) * i.g.ratio
						})
					}
				} else {
					u.css({
						width: "auto",
						height: "auto"
					});
					l = u.width();
					c = u.height();
					u.css({
						width: l * i.g.ratio,
						height: c * i.g.ratio,
						marginLeft: -(l * i.g.ratio / 2) + "px",
						marginTop: -(c * i.g.ratio / 2) + "px"
					})
				}
			}
			if (!s) {
				t.css({
					display: "none",
					visibility: "visible"
				})
			}
			e(n).find(".ls-shadow").css({
				height: e(n).find(".ls-shadow").data("originalHeight") * i.g.ratio
			});
			r();
			e(this).dequeue()
		};
		i.resizeYourLogo = function () {
			i.g.yourLogo.css({
				width: i.g.yourLogo.data("originalWidth") * i.g.ratio,
				height: i.g.yourLogo.data("originalHeight") * i.g.ratio
			}).fadeIn(300);
			var t = oR = oT = oB = "auto";
			if (i.g.yourLogo.data("originalLeft") && i.g.yourLogo.data("originalLeft").indexOf("%") != -1) {
				t = i.g.sliderWidth() / 100 * parseInt(i.g.yourLogo.data("originalLeft")) - i.g.yourLogo.width() / 2 + parseInt(e(n).css("padding-left"))
			} else {
				t = parseInt(i.g.yourLogo.data("originalLeft")) * i.g.ratio
			}
			if (i.g.yourLogo.data("originalRight") && i.g.yourLogo.data("originalRight").indexOf("%") != -1) {
				oR = i.g.sliderWidth() / 100 * parseInt(i.g.yourLogo.data("originalRight")) - i.g.yourLogo.width() / 2 + parseInt(e(n).css("padding-right"))
			} else {
				oR = parseInt(i.g.yourLogo.data("originalRight")) * i.g.ratio
			}
			if (i.g.yourLogo.data("originalTop") && i.g.yourLogo.data("originalTop").indexOf("%") != -1) {
				oT = i.g.sliderHeight() / 100 * parseInt(i.g.yourLogo.data("originalTop")) - i.g.yourLogo.height() / 2 + parseInt(e(n).css("padding-top"))
			} else {
				oT = parseInt(i.g.yourLogo.data("originalTop")) * i.g.ratio
			}
			if (i.g.yourLogo.data("originalBottom") && i.g.yourLogo.data("originalBottom").indexOf("%") != -1) {
				oB = i.g.sliderHeight() / 100 * parseInt(i.g.yourLogo.data("originalBottom")) - i.g.yourLogo.height() / 2 + parseInt(e(n).css("padding-bottom"))
			} else {
				oB = parseInt(i.g.yourLogo.data("originalBottom")) * i.g.ratio
			}
			i.g.yourLogo.css({
				left: t,
				right: oR,
				top: oT,
				bottom: oB
			})
		};
		i.resizeThumb = function () {
			e(n).find(".ls-thumbnail-slide a").css({
				width: parseInt(i.o.tnWidth * i.g.ratio),
				height: parseInt(i.o.tnHeight * i.g.ratio)
			});
			e(n).find(".ls-thumbnail-slide a:last").css({
				margin: 0
			});
			e(n).find(".ls-thumbnail-slide").css({
				height: parseInt(i.o.tnHeight * i.g.ratio)
			});
			var t = e(n).find(".ls-thumbnail");
			var r = i.o.tnContainerWidth.indexOf("%") == -1 ? parseInt(i.o.tnContainerWidth) : parseInt(parseInt(i.g.sliderOriginalWidth) / 100 * parseInt(i.o.tnContainerWidth));
			t.css({
				width: r * Math.floor(i.g.ratio * 100) / 100
			});
			if (t.width() > e(n).find(".ls-thumbnail-slide").width()) {
				t.css({
					width: e(n).find(".ls-thumbnail-slide").width()
				})
			}
		};
		i.changeThumb = function (t) {
			var r = t ? t: i.g.nextLayerIndex;
			e(n).find(".ls-thumbnail-slide a:not(.ls-thumb-" + r + ")").children().each(function () {
				e(this).removeClass("ls-thumb-active").stop().fadeTo(750, i.o.tnInactiveOpacity / 100)
			});
			e(n).find(".ls-thumbnail-slide a.ls-thumb-" + r).children().addClass("ls-thumb-active").stop().fadeTo(750, i.o.tnActiveOpacity / 100)
		};
		i.scrollThumb = function () {
			if (!e(n).find(".ls-thumbnail-slide-container").hasClass("ls-thumbnail-slide-hover")) {
				var t = e(n).find(".ls-thumb-active").length ? e(n).find(".ls-thumb-active").parent() : false;
				if (t) {
					var r = t.position().left + t.width() / 2;
					var i = e(n).find(".ls-thumbnail-slide-container").width() / 2 - r;
					i = i > 0 ? 0 : i;
					i = i < e(n).find(".ls-thumbnail-slide-container").width() - e(n).find(".ls-thumbnail-slide").width() ? e(n).find(".ls-thumbnail-slide-container").width() - e(n).find(".ls-thumbnail-slide").width() : i;
					e(n).find(".ls-thumbnail-slide").animate({
						marginLeft: i
					},
					600, "easeInOutQuad")
				}
			}
		};
		i.resizeSlider = function () {
			if (i.g.showSlider) {
				e(n).css({
					visibility: "visible"
				})
			}
			if (i.o.responsiveUnder > 0) {
				if (e(window).width() < i.o.responsiveUnder) {
					i.g.responsiveMode = true;
					i.g.sliderOriginalWidth = i.o.responsiveUnder + "px"
				} else {
					i.g.responsiveMode = false;
					i.g.sliderOriginalWidth = i.g.sliderOriginalWidthRU;
					i.g.ratio = 1
				}
			}
			if (i.g.responsiveMode) {
				var t = e(n).parent();
				e(n).css({
					width: t.width() - parseInt(t.css("padding-left")) - parseInt(t.css("padding-right")) - parseInt(e(n).css("padding-left")) - parseInt(e(n).css("padding-right"))
				});
				i.g.ratio = e(n).width() / parseInt(i.g.sliderOriginalWidth);
				e(n).css({
					height: i.g.ratio * parseInt(i.g.sliderOriginalHeight)
				})
			} else {
				i.g.ratio = 1;
				e(n).css({
					width: i.g.sliderOriginalWidth,
					height: i.g.sliderOriginalHeight
				})
			}
			if (e(n).closest(".ls-wp-fullwidth-container").length) {
				e(n).closest(".ls-wp-fullwidth-helper").css({
					height: e(n).outerHeight(true)
				});
				e(n).closest(".ls-wp-fullwidth-container").css({
					height: e(n).outerHeight(true)
				});
				e(n).closest(".ls-wp-fullwidth-helper").css({
					width: e(window).width(),
					left: -e(n).closest(".ls-wp-fullwidth-container").offset().left
				});
				if (i.g.sliderOriginalWidth.indexOf("%") != -1) {
					var r = parseInt(i.g.sliderOriginalWidth);
					var s = e("body").width() / 100 * r - (e(n).outerWidth() - e(n).width());
					e(n).width(s)
				}
			}
			e(n).find(".ls-inner").css({
				width: i.g.sliderWidth(),
				height: i.g.sliderHeight()
			});
			if (i.g.curLayer && i.g.nextLayer) {
				i.g.curLayer.css({
					width: i.g.sliderWidth(),
					height: i.g.sliderHeight()
				});
				i.g.nextLayer.css({
					width: i.g.sliderWidth(),
					height: i.g.sliderHeight()
				})
			} else {
				e(n).find(".ls-layer").css({
					width: i.g.sliderWidth(),
					height: i.g.sliderHeight()
				})
			}
		};
		i.animate = function () {
			var t = i.g.curLayer;
			i.o.cbAnimStart(i.g);
			i.g.isAnimating = true;
			if (i.o.thumbnailNavigation == "always") {
				i.changeThumb();
				i.scrollThumb()
			}
			i.g.nextLayer.addClass("ls-animating");
			var r = curLayerRight = curLayerTop = curLayerBottom = nextLayerLeft = nextLayerRight = nextLayerTop = nextLayerBottom = layerMarginLeft = layerMarginRight = layerMarginTop = layerMarginBottom = "auto";
			var s = nextLayerWidth = i.g.sliderWidth();
			var o = nextLayerHeight = i.g.sliderHeight();
			var u = i.g.prevNext == "prev" ? i.g.curLayer: i.g.nextLayer;
			var a = u.data("slidedirection") ? u.data("slidedirection") : i.o.slideDirection;
			var f = i.g.slideDirections[i.g.prevNext][a];
			if (f == "left" || f == "right") {
				s = curLayerTop = nextLayerWidth = nextLayerTop = 0;
				layerMarginTop = 0
			}
			if (f == "top" || f == "bottom") {
				o = r = nextLayerHeight = nextLayerLeft = 0;
				layerMarginLeft = 0
			}
			switch (f) {
			case "left":
				curLayerRight = nextLayerLeft = 0;
				layerMarginLeft = -i.g.sliderWidth();
				break;
			case "right":
				r = nextLayerRight = 0;
				layerMarginLeft = i.g.sliderWidth();
				break;
			case "top":
				curLayerBottom = nextLayerTop = 0;
				layerMarginTop = -i.g.sliderHeight();
				break;
			case "bottom":
				curLayerTop = nextLayerBottom = 0;
				layerMarginTop = i.g.sliderHeight();
				break
			}
			i.g.curLayer.css({
				left: r,
				right: curLayerRight,
				top: curLayerTop,
				bottom: curLayerBottom
			});
			i.g.nextLayer.css({
				width: nextLayerWidth,
				height: nextLayerHeight,
				left: nextLayerLeft,
				right: nextLayerRight,
				top: nextLayerTop,
				bottom: nextLayerBottom
			});
			if (i.o.animateFirstLayer && i.g.layersNum == 1) {
				var l = 0
			} else {
				var l = i.g.curLayer.data("delayout") ? parseInt(i.g.curLayer.data("delayout")) : i.o.delayOut;
				var c = i.g.curLayer.data("durationout") ? parseInt(i.g.curLayer.data("durationout")) : i.o.durationOut;
				var h = i.g.curLayer.data("easingout") ? i.g.curLayer.data("easingout") : i.o.easingOut;
				i.g.curLayer.delay(l + c / 15).animate({
					width: s,
					height: o
				},
				c, h, function () {
					t.find(' > *[class*="ls-s"]').stop(true, true);
					i.g.curLayer = i.g.nextLayer;
					i.g.curLayerIndex = i.g.nextLayerIndex;
					e(n).find(".ls-layer").removeClass("ls-active");
					e(n).find(".ls-layer:eq(" + (i.g.curLayerIndex - 1) + ")").addClass("ls-active").removeClass("ls-animating");
					e(n).find(".ls-bottom-slidebuttons a").removeClass("ls-nav-active");
					e(n).find(".ls-bottom-slidebuttons a:eq(" + (i.g.curLayerIndex - 1) + ")").addClass("ls-nav-active");
					i.g.isAnimating = false;
					i.o.cbAnimStop(i.g);
					if (i.g.autoSlideshow) {
						i.timer()
					}
				});
				i.g.curLayer.find(' > *[class*="ls-s"]').each(function () {
					var t = e(this).data("slidedirection") ? e(this).data("slidedirection") : f;
					var n, r;
					switch (t) {
					case "left":
						n = -i.g.sliderWidth();
						r = 0;
						break;
					case "right":
						n = i.g.sliderWidth();
						r = 0;
						break;
					case "top":
						r = -i.g.sliderHeight();
						n = 0;
						break;
					case "bottom":
						r = i.g.sliderHeight();
						n = 0;
						break
					}
					var s = e(this).data("slideoutdirection") ? e(this).data("slideoutdirection") : false;
					switch (s) {
					case "left":
						n = i.g.sliderWidth();
						r = 0;
						break;
					case "right":
						n = -i.g.sliderWidth();
						r = 0;
						break;
					case "top":
						r = i.g.sliderHeight();
						n = 0;
						break;
					case "bottom":
						r = -i.g.sliderHeight();
						n = 0;
						break
					}
					var o = i.g.curLayer.data("parallaxout") ? parseInt(i.g.curLayer.data("parallaxout")) : i.o.parallaxOut;
					var u = parseInt(e(this).attr("class").split("ls-s")[1]) * o;
					var a = e(this).data("delayout") ? parseInt(e(this).data("delayout")) : i.o.delayOut;
					var l = e(this).data("durationout") ? parseInt(e(this).data("durationout")) : i.o.durationOut;
					var c = e(this).data("easingout") ? e(this).data("easingout") : i.o.easingOut;
					if (s == "fade" || !s && t == "fade") {
						e(this).delay(a).fadeOut(l, c)
					} else {
						e(this).stop().delay(a).animate({
							marginLeft: -n * u,
							marginTop: -r * u
						},
						l, c)
					}
				})
			}
			var p = i.g.nextLayer.data("delayin") ? parseInt(i.g.nextLayer.data("delayin")) : i.o.delayIn;
			var d = i.g.nextLayer.data("durationin") ? parseInt(i.g.nextLayer.data("durationin")) : i.o.durationIn;
			var v = i.g.nextLayer.data("easingin") ? i.g.nextLayer.data("easingin") : i.o.easingIn;
			i.g.nextLayer.delay(l + p).animate({
				width: i.g.sliderWidth(),
				height: i.g.sliderHeight()
			},
			d, v);
			i.g.nextLayer.find(' > *[class*="ls-s"]').each(function () {
				var t = e(this).data("slidedirection") ? e(this).data("slidedirection") : f;
				var n, r;
				switch (t) {
				case "left":
					n = -i.g.sliderWidth();
					r = 0;
					break;
				case "right":
					n = i.g.sliderWidth();
					r = 0;
					break;
				case "top":
					r = -i.g.sliderHeight();
					n = 0;
					break;
				case "bottom":
					r = i.g.sliderHeight();
					n = 0;
					break;
				case "fade":
					r = 0;
					n = 0;
					break
				}
				var s = i.g.nextLayer.data("parallaxin") ? parseInt(i.g.nextLayer.data("parallaxin")) : i.o.parallaxIn;
				var o = parseInt(e(this).attr("class").split("ls-s")[1]) * s;
				var u = e(this).data("delayin") ? parseInt(e(this).data("delayin")) : i.o.delayIn;
				var a = e(this).data("durationin") ? parseInt(e(this).data("durationin")) : i.o.durationIn;
				var c = e(this).data("easingin") ? e(this).data("easingin") : i.o.easingIn;
				if (t == "fade") {
					e(this).css({
						display: "none",
						marginLeft: 0,
						marginTop: 0
					}).delay(l + u).fadeIn(a, c, function () {
						if (i.o.autoPlayVideos == true) {
							e(this).find(".ls-videopreview").click()
						}
						if (e(this).data("showuntil") > 0) {
							i.sublayerShowUntil(e(this))
						}
					})
				} else {
					e(this).css({
						marginLeft: n * o,
						marginTop: r * o,
						display: "block"
					}).stop().delay(l + u).animate({
						marginLeft: 0,
						marginTop: 0
					},
					a, c, function () {
						if (i.o.autoPlayVideos == true) {
							e(this).find(".ls-videopreview").click()
						}
						if (e(this).data("showuntil") > 0) {
							i.sublayerShowUntil(e(this))
						}
					})
				}
			})
		};
		i.sublayerShowUntil = function (e) {
			var t = i.g.curLayer;
			if (i.g.prevNext != "prev" && i.g.nextLayer) {
				t = i.g.nextLayer
			}
			var n = t.data("slidedirection") ? t.data("slidedirection") : i.o.slideDirection;
			var r = i.g.slideDirections[i.g.prevNext][n];
			var s = e.data("slidedirection") ? e.data("slidedirection") : r;
			var o, u;
			switch (s) {
			case "left":
				o = -i.g.sliderWidth();
				u = 0;
				break;
			case "right":
				o = i.g.sliderWidth();
				u = 0;
				break;
			case "top":
				u = -i.g.sliderHeight();
				o = 0;
				break;
			case "bottom":
				u = i.g.sliderHeight();
				o = 0;
				break
			}
			var a = e.data("slideoutdirection") ? e.data("slideoutdirection") : false;
			switch (a) {
			case "left":
				o = i.g.sliderWidth();
				u = 0;
				break;
			case "right":
				o = -i.g.sliderWidth();
				u = 0;
				break;
			case "top":
				u = i.g.sliderHeight();
				o = 0;
				break;
			case "bottom":
				u = -i.g.sliderHeight();
				o = 0;
				break
			}
			var f = i.g.curLayer.data("parallaxout") ? parseInt(i.g.curLayer.data("parallaxout")) : i.o.parallaxOut;
			var l = parseInt(e.attr("class").split("ls-s")[1]) * f;
			var c = parseInt(e.data("showuntil"));
			var h = e.data("durationout") ? parseInt(e.data("durationout")) : i.o.durationOut;
			var p = e.data("easingout") ? e.data("easingout") : i.o.easingOut;
			if (a == "fade" || !a && s == "fade") {
				e.delay(c).fadeOut(h, p)
			} else {
				e.delay(c).animate({
					marginLeft: -o * l,
					marginTop: -u * l
				},
				h, p)
			}
		};
		i.debug = function () {
			i.d = {
				history: e("<div>").css({
					color: "white",
					"text-shadow": "none",
					fontFamily: 'HelveticaNeue-Light, "Helvetica Neue Light", Helvetica, Arial, serif',
					lineHeight: "normal",
					fontWeight: "normal",
					fontSize: "14px",
					"-webkit-font-smoothing": "antialiased"
				}),
				add: function (e, t) {
					var n = "    ";
					var r = "<br>";
					if (t) {
						n = "<br><b>";
						r = "</b><br><br>"
					}
					i.d.history.append(n + e + r)
				},
				addFunction: function (e) {
					i.d.history.find("span:last").hover(function () {
						e.css({
							border: "2px solid red"
						})
					},
					function () {
						e.css({
							border: "0px"
						})
					})
				},
				show: function () {
					if (!e("body").find(".ls-debug-console").length) {
						var t = e("<div>").addClass("ls-debug-console").css({
							position: "fixed",
							zIndex: "10000000000",
							top: "10px",
							right: "10px",
							width: "300px",
							padding: "20px",
							background: "black",
							"border-radius": "10px",
							height: e(window).height() - 60,
							opacity: 0,
							marginRight: 150
						}).appendTo(e("body")).animate({
							marginRight: 0,
							opacity: .9
						},
						600, "easeInOutQuad").click(function (t) {
							if (t.shiftKey && t.altKey) {
								e(this).animate({
									marginRight: 150,
									opacity: 0
								},
								600, "easeInOutQuad", function () {
									e(this).remove()
								})
							}
						});
						var n = e("<div>").css({
							width: "100%",
							height: "100%",
							overflow: "auto"
						}).appendTo(t);
						var r = e("<div>").css({
							width: "100%"
						}).appendTo(n).append(i.d.history)
					}
				},
				hide: function () {
					e("body").find(".ls-debug-console").remove()
				}
			};
			e(n).click(function (e) {
				if (e.shiftKey && e.altKey) {
					i.d.show()
				}
			})
		};
		i.load()
	};
	t.global = {
		version: "3.5",
		paused: false,
		pausedByVideo: false,
		autoSlideshow: false,
		isAnimating: false,
		layersNum: null,
		prevNext: "next",
		slideTimer: null,
		sliderWidth: null,
		sliderHeight: null,
		slideDirections: {
			prev: {
				left: "right",
				right: "left",
				top: "bottom",
				bottom: "top"
			},
			next: {
				left: "left",
				right: "right",
				top: "top",
				bottom: "bottom"
			}
		},
		v: {
			d: 500,
			fo: 750,
			fi: 500
		}
	};
	t.options = {
		autoStart: true,
		firstLayer: 1,
		twoWaySlideshow: true,
		keybNav: true,
		imgPreload: true,
		navPrevNext: true,
		navStartStop: true,
		navButtons: true,
		skin: "glass",
		skinsPath: "/layerslider/skins/",
		pauseOnHover: true,
		globalBGColor: "transparent",
		globalBGImage: false,
		animateFirstLayer: true,
		yourLogo: false,
		yourLogoStyle: "left: -10px; top: -10px;",
		yourLogoLink: false,
		yourLogoTarget: "_blank",
		touchNav: true,
		loops: 0,
		forceLoopNum: true,
		autoPlayVideos: true,
		autoPauseSlideshow: "auto",
		youtubePreview: "maxresdefault.jpg",
		responsive: true,
		randomSlideshow: false,
		responsiveUnder: 0,
		sublayerContainer: 0,
		thumbnailNavigation: "hover",
		tnWidth: 100,
		tnHeight: 60,
		tnContainerWidth: "60%",
		tnActiveOpacity: 35,
		tnInactiveOpacity: 100,
		hoverPrevNext: true,
		hoverBottomNav: false,
		cbInit: function (e) {},
		cbStart: function (e) {},
		cbStop: function (e) {},
		cbPause: function (e) {},
		cbAnimStart: function (e) {},
		cbAnimStop: function (e) {},
		cbPrev: function (e) {},
		cbNext: function (e) {},
		slideDirection: "right",
		slideDelay: 4e3,
		parallaxIn: .45,
		parallaxOut: .45,
		durationIn: 1500,
		durationOut: 1500,
		easingIn: "easeInOutQuint",
		easingOut: "easeInOutQuint",
		delayIn: 0,
		delayOut: 0
	}
})(jQuery)