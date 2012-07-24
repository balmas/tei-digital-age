(function(window) {
    teilod = {
    
        /**
         * Map of languge code to lexicon for lemma lookup
         **/
        lexicons: {
            'grc' : 'lsj',
            'lat' : 'ls'
        },
        
        /**
         * Map of language codes to morphology engine for form lookup
         */
        morphEngines: {
            'grc': 'morpheus',
            'lat': 'morpheus',
        },
        
        /**
         * Url to morphology service
         */
        morphUrl : 'http://shell.perseus.tufts.edu:8181/bsp/morphologyservice/analysis/word?word=WORD&lang=LANG&engine=ENGINE',
        
        /**
         * Url to lexicon service
         */
        lexiconUrl: 'http://repos1.alpheios.net/exist/rest/db/xq/lexi-get.xq?lx=LEXICON&lg=LANG&out=html&l=LEMMA',
        
        /**
         * Url to treebank viewer
         */
        syntaxUrl: 'http://repos.alpheios.net:8081/exist/rest/db/xq/treebank-xb-viewer.xq?&fmt=FORMAT&lang=LANG',
        
        /**
         * jQuery document ready function
         */
        ready : function() {
            $('.tei-word').dblclick(teilod.getLemmas);
            $('.tei-word[data-corresp]').mouseover(teilod.showTranslation);
            $('.tei-word[data-corresp]').mouseout(teilod.hideTranslation);
            $('.tei-aligned-word[data-corresp]').mouseover(teilod.showTranslation);
            $('.tei-aligned-word[data-corresp]').mouseout(teilod.hideTranslation);
            $('.tbref').click(teilod.getSyntax);
        },
        
        /**
         * Click handler for syntax lookup. 
         */
        getSyntax: function(a_event)
        {
            // update the syntax frame to show data is loading
            $("#tei-syntax-frame").contents().find('body').prepend('<div class="loading">Loading...</div>');
            
            // retrieve sentence XML from the document
            var treebank = $(".data sentence",this);
            var fmt = treebank.get(0).getAttribute("format");
            var lang = treebank.get(0).getAttribute("xml:lang");
            var sent =  '<sentence fmt="' + fmt + '" lang="' + lang + '">' + $(".data sentence",this).get(0).innerHTML + '</sentence>';
            
            // send the sentence to the remote treebank view loader app
            var url = teilod.syntaxUrl;
            url = url.replace('FORMAT',fmt);
            url = url.replace('LANG',lang);
            $.ajax(url, { 
                 type: 'GET',  
                 dataType: "xml",
                 isLocal: "true",
                 success: function(data) {
                     var jdata = $(data).contents().find('body').html();
                     $("#tei-syntax-frame").contents().find('body').html(jdata);
                     $("#tei-syntax-frame").contents().find('#sentence-xml').html(sent);
                     $("#tei-syntax-frame").contents().find('#sentence-xml').change();
                 },
                 error: function() {
                    $("#tei-syntax-frame").contents().find('body').html('<div class="error">Error Loading Syntax View</div>');
                 }
             });
         },
         
        /**
         * Mouseover handler for highlighting aligned translation
         */
         showTranslation: function(a_event) {
            var resource = $(this).attr('data-corresp');
            var isTranslation = false;
            if ($(this).parents('.tei-aligned-text').length > 0) {
                isTranslation = true;
            }
            if (resource != null && resource != '') {
                var resources = resource.split(' ');
                for (var i=0; i<resources.length; i++) {
                    var node;
                    if (isTranslation) {
                        node = $(".tei-word[data-n=" + resources[i] + "]")
                    }
                    else {
                        node = $(".tei-aligned-text .tei-aligned-word[data-n=" + resources[i] + "]")
                    }
                    $(this).addClass('highlight');
                    node.addClass('highlight');
                }
            }
            
        },
        
         /**
         * Mouseover handler for removing highlight from aligned translation
         */
        hideTranslation: function(a_event) {
            var resource = $(this).attr('data-corresp');
            var isTranslation = false;
            if ($(this).parents('.tei-aligned-text').length > 0) {
                isTranslation = true;
            }
            if (resource != null && resource != '') {
                var resources = resource.split(' ');
                for (var i=0; i<resources.length; i++) {
                     if (isTranslation) {
                       node = $(".tei-word[data-n=" + resources[i] + "]")
                    }
                    else {
                        node = $(".tei-aligned-text .tei-aligned-word[data-n=" + resources[i] + "]")
                        
                    }
                    $(this).removeClass('highlight');
                    node.removeClass('highlight');
                }
            }
        },
        
        /**
         * Use Morphology service to analyze form and identify lemma and lookup lemma in the lexicon service.
         */
        getLemmas : function(a_event) {
            $('#tei-lemmas').html('<div id="tei-lemmas-loading">Loading lexicon....</div>');
            var lang = teilod.getLanguageForElement(this);
            if (lang != null && lang != '') {
                var url = teilod.morphUrl;
                url= url.replace('WORD',$(this).text()).replace('LANG',lang).replace('ENGINE',teilod.morphEngines[lang]);
                $.ajax(
                        url, {
                        type: 'GET',
                        dataType: 'json',
                        success: function(data,textStatus,xR) {
                            var parses = [];
                            var annotations = data.RDF.Annotation.Body;
                            var x = typeof annotations;
                            if (annotations[0] != null) 
                            {
                                for (var i in annotations) {
                                        parses[i] = annotations[i];
                                }
                            }
                            else {
                                parses[i] = annotations;
                            }
                            for (var i in parses) {
                                var entries = [];
                                var entry = parses[i].rest.entry;
                                if (entry[0] != null) {
                                    for (j in entry) {
                                        entries[j] = entry[j];
                                    }
                                }
                                else {
                                    entries[0] = entry;
                                }
                                for (var k in entries) {
                                    var lexUrl = teilod.lexiconUrl.replace('LEMMA',entries[k].dict.hdwd.$).replace('LEXICON',teilod.lexicons[lang]).replace('LANG',lang);
                                    $.ajax( lexUrl, {
                                       type: 'GET',
                                       dataType: 'html',
                                       success: function(data,textStatus,xR) {
                                        $("#tei-lemmas-loading").remove();
                                        $("#tei-lemmas .error").remove();
                                        $('#tei-lemmas').append(data);
                                       },
                                       error: function() {
                                           $('#tei-lemmas-loading').remove();
                                           $('#tei-lemmas').append('<div class="error">Lexicon lookup failed.</div>');
                                       }
                                    });
                                }
                            }
                            
                        },
                        error: function(xR,textstatus,error) {
                            alert("failure" + textstatus + error);
                        }
                    });
                }
            },
            
            /**
             * get the language of the selected element (from the element itself or its nearest parent)
             */
            getLanguageForElement: function(a_elem) {
                var lang_key = null;
                var elem_lang = null;
                var checkSet = $(a_elem).add($(a_elem).parents());
                // iterate through the set of the element and its parents
                // taking the value of the first lang or xml:lang attribute found
                // order of parents added in checkSet is closest-first
                for (var i=0; i<checkSet.length; i++)
                {    
                    var elem = checkSet.eq(i)
                    elem_lang = elem.attr("lang") || elem.attr("xml:lang");
                    if (elem_lang)
                    {
                        break;
                    }
                }                       
                return elem_lang;
            }
    };
    window.teilod = teilod;
})(window);
