/*
 Copyright (C) 2015 Baa. All rights reserved.
 See LICENSE.txt for this sample’s licensing information
 */

/*
 Example code from Ray Wenderlich:
 http://www.raywenderlich.com/114886/beginning-tvos-development-with-tvml-tutorial
 */


var Presenter = {
	makeDocument: function(resource) {
		if (!Presenter.parser) {
			Presenter.parser = new DOMParser();
		}
		var doc = Presenter.parser.parseFromString(resource, "application/xml");
		return doc;
	},

	modalDialogPresenter: function(xml) {
		navigationDocument.presentModal(xml);
	},

	/*
	  call swift.XMLConverter with...
		template: view
		pmsId: id
		pmsPath: path
	 */
	setupViewDocument: function(view, pmsId, pmsPath, useMustache) {
		console.log("load");

		var docString,
			parser,
			doc;

		if (useMustache)
			docString = swiftInterface.getViewIdPathUseMustache(view, pmsId, pmsPath, useMustache)
		else
			docString = swiftInterface.getViewIdPath(view, pmsId, pmsPath);

		parser = new DOMParser();
		doc = parser.parseFromString(docString, "application/xml");

		Presenter.bindEvents(doc);

		return doc
	},

	load: function(view, pmsId, pmsPath, title, useMustache) {
		if (typeof title != "string")
			title = "";

		if (useMustache) {
			var loadingDoc = createSpinner(title),
				parser = new DOMParser();

			navigationDocument.pushDocument(loadingDoc)

			swiftInterface.getViewIdPathUseMustacheCompletion(view, pmsId, pmsPath, true, function(template) {
				var doc = parser.parseFromString(template, "application/xml");
				Presenter.bindEvents(doc);
				navigationDocument.replaceDocument(doc, loadingDoc);
			})


			return;
		}

		var loadingDoc = createSpinner("");
		loadingDoc.addEventListener("load", function() {
			var doc = Presenter.setupViewDocument(view, pmsId, pmsPath, useMustache);
			navigationDocument.replaceDocument(doc, loadingDoc);
		});
		navigationDocument.pushDocument(loadingDoc);
		//navigationDocument.dismissModal();  // just in case?!  // todo: if (isModal)...?
	},

	loadAndSwap: function(view, pmsId, pmsPath, title, useMustache, loadingIndicator) {
		if (typeof title != "string")
			title = "";

		var currentDoc = navigationDocument.documents[navigationDocument.documents.length - 1];
		var loadingDoc = createSpinner(title);

		if (useMustache) {
			var parser = new DOMParser();

			if (loadingIndicator) {
				var loadingDoc = createSpinner(title);

				navigationDocument.replaceDocument(loadingDoc, currentDoc)
			}

			swiftInterface.getViewIdPathUseMustacheCompletion(view, pmsId, pmsPath, true, function(template) {
				var doc = parser.parseFromString(template, "application/xml");
				Presenter.bindEvents(doc);
				navigationDocument.replaceDocument(doc, loadingIndicator ? loadingDoc : currentDoc);
			})

			return;
		}

		loadingDoc.addEventListener("load", function() {
			var doc = Presenter.setupViewDocument(view, pmsId, pmsPath);
			navigationDocument.replaceDocument(doc, loadingDoc);
		});
		navigationDocument.replaceDocument(loadingDoc, currentDoc);
		// navigationDocument.dismissModal();  // just in case?!  // todo: if (isModal)...?
	},

	swapElements: function(view, pmsId, pmsPath, title, useMustache, elements, autoFocusElement) {
		var parser = new DOMParser();

		swiftInterface.getViewIdPathUseMustacheCompletion(view, pmsId, pmsPath, true, function(template) {
			setTimeout(function() {
				var doc = parser.parseFromString(template, "application/xml");
				var activeDocument = getActiveDocument();

				for (i in elements) {
					if (typeof activeDocument.getElementById(elements[i]) == 'undefined')
						continue;

					console.log(doc.getElementById(elements[i]).outerHTML)

					activeDocument.getElementById(elements[i]).outerHTML = doc.getElementById(elements[i]).outerHTML

					if (elements[i] == autoFocusElement) {
						console.log("Auto focus element: " + autoFocusElement)
						activeDocument.getElementById(elements[i]).setAttribute("autoHighlight", "true");
					}
				}
			}, 500);
		})
	},

	close() {
		navigationDocument.popDocument();
	},

	loadContext(view, pmsId, pmsPath) {
		var doc = Presenter.setupViewDocument(view, pmsId, pmsPath);
		navigationDocument.presentModal(doc);
	},

	loadContextWithData(view, data) {
		var parser = new DOMParser(),
			docString = swiftInterface.getViewData(view, data),
			doc = parser.parseFromString(docString, "application/xml");

		Presenter.bindEvents(doc);
		navigationDocument.presentModal(doc);
	},


	closeContext() {
		navigationDocument.dismissModal();
	},

	loadMenuContent: function(view, pmsId, pmsPath, useMustache) {
		console.log("loadMenuContent");
		var elem = this.event.target; // todo: check event existing
		var id = elem.getAttribute("id");

		var feature = elem.parentNode.getFeature("MenuBarDocument");
		if (feature) {
			var loadingDoc = createSpinner("");
			if (useMustache) {
				var parser = new DOMParser();

				feature.setDocument(loadingDoc, elem);

				swiftInterface.getViewIdPathUseMustacheCompletion(view, pmsId, pmsPath, true, function(template) {
					var doc = parser.parseFromString(template, "application/xml");
					Presenter.bindEvents(doc);
					feature.setDocument(doc, elem);
				})


				return;
			}



			var currentDoc = feature.getDocument(elem);
			if (!currentDoc // todo: better algorithm to decide on doc reload
				|| (id != "Search" && id != "Settings")) { // currently: force reload on each but Settings, Search

				var loadingDoc = createSpinner("");
				feature.setDocument(loadingDoc, elem);
				var doc = Presenter.setupViewDocument(view, pmsId, pmsPath);
				feature.setDocument(doc, elem);
			}
		}
	},

	loadParade: function(view, pmsId, pmsPath) {
		console.log("loadParade");
		var elem = this.event.target;
		if (!elem) { // no element?
			return;
		}
		var elem = elem.getElementByTagName("relatedContent");
		if (elem.hasChildNodes()) { // related content already populated?
			return;
		}

		// update view
		var doc = Presenter.setupViewDocument(view, pmsId, pmsPath);
		var elemNew = doc.getElementByTagName("relatedContent");

		if (elem && elemNew) {
			elem.innerHTML = elemNew.innerHTML;
		}
	},

	bindEvents: function(doc) {
		// events: https://developer.apple.com/library/tvos/documentation/TVMLKit/Reference/TVViewElement_Ref/index.html#//apple_ref/c/tdef/TVElementEventType
		doc.addEventListener("select", Presenter.onSelect.bind(Presenter));
		doc.addEventListener("holdselect", Presenter.onHoldSelect.bind(Presenter));
		doc.addEventListener("play", Presenter.onPlay.bind(Presenter));
		doc.addEventListener("highlight", Presenter.onHighlight.bind(Presenter));
		doc.addEventListener("load", Presenter.onLoad.bind(Presenter)); // setup search for char entered
	},

	// store event for downstream use
	event: "",

	/*
	 event handlers
	 */
	onSelect: function(event) {
		console.log("onSelect " + event);
		this.event = event;
		var elem = event.target;

		if (elem) {
			var id = elem.getAttribute("id");
			var onSelect = elem.getAttribute("onSelect"); // get onSelect=...
			with(event) {
				eval(onSelect);
			}
		}
	},

	onHoldSelect: function(event) {
		console.log("onHoldSelect " + event);
		this.event = event;
		var elem = event.target;

		if (elem) {
			var id = elem.getAttribute("id");
			var onHoldSelect = elem.getAttribute("onHoldSelect"); // get onHoldSelect=...
			if (!onHoldSelect) {
				onHoldSelect = elem.getAttribute("onSelect"); // fall back to onSelect=...
			}
			with(event) {
				eval(onHoldSelect);
			}
		}
	},

	onPlay: function(event) {
		console.log("onPlay " + event);
		this.event = event;
		var elem = event.target;

		if (elem) {
			var id = elem.getAttribute("id");
			var onPlay = elem.getAttribute("onPlay"); // get onPlay=...
			if (!onPlay) {
				onPlay = elem.getAttribute("onSelect"); // fall back to onSelect=...
			}
			with(event) {
				eval(onPlay);
			}
		}

	},

	onHighlight: function(event) {
		console.log("onHighlight " + event);
		this.event = event;
		var elem = event.target;

		if (elem) {
			var onHighlight = elem.getAttribute("onHighlight"); // get onHighlight=...
			if (onHighlight) {
				eval(onHighlight);
			}
		}
	},

	// grab keyboard changes for searchField
	onLoad: function(event) {
		var elem = event.target;

		if (elem) {
			var onLoad = elem.getAttribute("onLoad"); // get onLoad=...
			with(event) {
				eval(onLoad);
			}
		}
	}
}