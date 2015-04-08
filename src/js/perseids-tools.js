var PerseidsTools;
PerseidsTools = PerseidsTools || {};
PerseidsTools.LDResults = {};
PerseidsTools.endpointMap = {};


PerseidsTools.LDResults.set_endpoint_map = function(_elem, _results) {
    var key = jQuery(_elem).attr('data-result-id');
    PerseidsTools.endpointMap[key] = _results;
}

 
PerseidsTools.LDResults.thumbs = function(_elem, _results) {
  
  if ( _results.length == 0 ) {
    $( '.perseidsld_query_obj_simple' ).remove();
  } else {
    for ( var i=0, ii=_results.length; i<ii; i++ ) {
       var src = _results[i];
        var imgUrn = '<img src="'+ src + '" height="100px" onclick="PerseidsTools.do_image_link(this);" title="Click to Zoom"/>';
        jQuery( _elem ).append( imgUrn );
    }

  }
}


// click handler for a span which has a data-facs attribute 
PerseidsTools.do_image_link = function(a_elem) {
    var uri = jQuery(a_elem).attr("src");
    if (! uri) {   
        uri = jQuery(a_elem).attr("data-facs");
    }
    var url = null;
    // if the facs value is a full URL, just use it
    if (uri && uri.match(/^http/)) {
        url = uri;
    // if the facs value references a CITE urn, try to bring it up in the Image Viewer
    } else if (uri && uri.match(/^urn:cite:/)) {
        var collection = uri.match(/^(urn:cite:.*?)\./);
        if (collection && PerseidsTools.endpointMap.viewer[collection[1]]) {
            url = PerseidsTools.endpointMap.viewer[collection[1]] + uri;
        } else {
            url = citeUrl + uri;
        }
    } else {
        // otherwise do nothing
    }
    if (url != null) {
        jQuery('#ict_frame').attr("src",url);
    }
    if (!jQuery("#ict_frame").is(':visible')) {
	    jQuery('#ict_frame').slideDown("slow", function() {$("#hideictframe").show()});
    }
    return false;
};


PerseidsTools.hideImageViewer = function() {
    $("#hideictframe").hide();
    $("#ict_frame").hide("slow");
};
