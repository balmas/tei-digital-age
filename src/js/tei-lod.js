(function(window) {
    teilod = {
    
        /**
         * Map of languge code to lexicon for lemma lookup
         **/
        lexicons: {
            'grc' : 'lsj',
            'lat' : 'ls',
            'ara' : 'lan'
        },
        
        /**
         * Map of language codes to morphology engine for form lookup
         */
        morphEngines: {
            'grc': 'morpheusgrc',
            'lat': 'morpheuslat',
            'ara': 'aramorph'
        },
        
        /**
         * Url to morphology service
         */
        morphUrl : 'http://services.perseids.org/bsp/morphologyservice/analysis/word?word=WORD&lang=LANG&engine=ENGINE',
        
        /**
         * Url to lexicon service
         */
        lexiconUrl: 'http://repos1.alpheios.net/exist/rest/db/xq/lexi-get.xq?lx=LEXICON&lg=LANG&out=html&l=LEMMA',
        
        /**
         * Url to treebank viewer
         */
        syntaxUrl: 'http://repos.alpheios.net:8081/exist/rest/db/xq/treebank-xb-viewer.xq?&fmt=FORMAT&lang=LANG',

        /**
         * Theme words
         */
        theme_words: {},
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
            teilod.makeGraph();
            PerseidsLD.do_verb_query();
            PerseidsLD.do_simple_query();
            $("#tei-analyses").click(function() { PerseidsTools.do_image_link(this); });
            $(".tei-word[data-ana]").each(
              function() {
   
                if ( ! teilod.theme_words[$(this).attr('data-ana')]) {
                  teilod.theme_words[$(this).attr('data-ana')] = {};
                }
                teilod.theme_words[$(this).attr('data-ana')][$(this).text()] = 1; 
              }
            );
            $(".tei-annotation-target").each(function() {
                var elem = this;
                teilod.findCite(
                    $.trim($(elem).text()), 
                    function(data) { 
                        if (data.author) { $(elem).html(data.author + " " + data.work + " " + data.section); } 
                    });
            });
            
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
                    if (node.length > 0) {
                        if (isTranslation) {
                          $('.tei_body').stop(true,true);
                          $('.tei_body').animate({
                            scrollTop: teilod.scrollTo($(node[0]))},1500);
                        } else {
                          $('.tei-aligned-text').stop(true,true);
                          $('.tei-aligned-text').animate({
                            scrollTop: teilod.scrollTo($(node[0]))},1500);
                        }
                    }
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
            },
            
            makeGraph: function() {
                
                var margin = {top: 20, right: 20, bottom: 30, left: 40},
                    width = 960 - margin.left - margin.right,
                    height = 250 - margin.top - margin.bottom;
                
                var x = d3.scale.ordinal()
                    .rangeRoundBands([0, width], .1);
                
                var y = d3.scale.linear()
                    .range([height, 0]);
                
                var xAxis = d3.svg.axis()
                    .scale(x)
                    .tickFormat('')
                    .orient("bottom");
                
                var yAxis = d3.svg.axis()
                    .scale(y)
                    .orient("left")
                    .ticks(10, "");
                
                var svg = d3.select("#themegraph").append("svg")
                    .attr("width", width + margin.left + margin.right)
                    .attr("height", height + margin.top + margin.bottom)
                  .append("g")
                    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
                
                var data = d3.csv.parseRows($.trim($("#tei-analyses").text()), function(d) { return { "letter" : d[0], "frequency": d[1]}; });
                x.domain(data.map(function(d) { return d.letter; }));
                y.domain([0, d3.max(data, function(d) { return d.frequency; })]);
                svg.append("g")
                    .attr("class", "x axis")
                    .attr("transform", "translate(0," + height + ")")
                    .call(xAxis);
                     
                svg.append("g")
                    .attr("class", "y axis")
                    .call(yAxis)
                    .append("text")
                    .attr("transform", "rotate(-90)")
                    .attr("y", 6)
                    .attr("dy", ".71em")
                    .style("text-anchor", "end")
                    .text("Occurrences");

                var bar = svg.selectAll(".bar")
                    .data(data)
                    .enter().append("g")
                    .attr("class","themebar")
                    .attr("transform",function(d,i) {
                      return "translate( " + x(d.letter) + "," + 0 + " )";    
                     });
                bar.append("rect")
                    .attr("class", "bar")
                    .attr("width", x.rangeBand())
                    .attr("y", function(d) { return y(d.frequency); })
                    .attr("height", function(d) { return height - y(d.frequency)})
                    .attr("data-text", function(d) { return $.trim(d.letter)});
                bar.append("text")
                    .attr("class", "barlabel")
                    .attr("x", -height)
                    .attr("dx", ".5em")
                    .attr("dy", "1.5em")
                    .attr("transform","rotate(-90)")
                    .text( function(d) { return $.trim(d.letter)});
                  
               $(".bar").mouseover(function() {
                    $(".tei-word[data-ana='" + $(this).attr("data-text") + "']").addClass("highlight-theme");
                    var top = $(".tei-word[data-ana='" + $(this).attr("data-text") + "']");
                    if (top.length > 0) {
                      $(".tei-body").stop(true,true);
                      $('.tei_body').animate({
                        scrollTop: teilod.scrollTo($(top[0]))},1500);
                    }
                });
               $(".bar").mouseout(function() {
                    $(".tei-word[data-ana='" + $(this).attr("data-text") + "']").removeClass("highlight-theme");
                });
               $(".bar").click(function() { teilod.toggleTheme(this)});
        },

        toggleTheme: function(a_elem) {
            var theme = $(a_elem).attr("data-text");
            var words = $(".tei-word[data-ana='" + theme + "']");
            var images = $("#tei-images div[data-facs-theme='" + theme + "'] span");
            var themeclass = "highlight-theme";
            var clickclass = "click-theme";
            var toggleOn = true;
            var oldclass = $(a_elem).attr("class");
            if (oldclass.match(clickclass)) {
              toggleOn = false;
            }
            if (toggleOn) {
              /** jQuery hasClass isn't working on the SVG element so we need to add/remove class manually **/
              var oldclass = $(a_elem).attr("class");
              $(a_elem).attr("class",oldclass + " " + clickclass);
              words.addClass(clickclass);
              var top = $(".tei-word[data-ana='" + $(a_elem).attr("data-text") + "']");
              if (top.length > 0) {
                $('.tei_body').stop(true,true);
                $('.tei_body').animate({scrollTop: teilod.scrollTo($(top[0]))},1500);
              }
              if (images.length == 1 ) {
                PerseidsTools.do_image_link(images.get(0));
                if (!jQuery("#ict_frame").is(':visible')) {
	          jQuery('#ict_frame').slideDown("slow", function() {$("#hideictframe").show()});
                }
              } else if (images.length > 1) {
                  console.log("We need to offer pagination of images");
              }
              $("#tei-theme-words ul").empty();
              $("#tei-theme-words h2").html(theme);
              $.each(teilod.theme_words[theme],
                function(key,value) {
                  $("#tei-theme-words ul").append("<li>" + key + "</li>");
                }  
              );
             $("#tei-theme-words").show("slow");
              //alert("This will eventually search all documents for " + $(this).attr("data-text") + " and display browseable results below");
            } else {
              /** jQuery hasClass isn't working on the SVG element so we need to add/remove class manually **/
              $(a_elem).attr("class",oldclass.replace(' ' + clickclass, ""));
              words.removeClass(clickclass);
              if (images.length > 0 ) {
	        jQuery('#ict_frame').slideUp("slow", function() {$("#hideictframe").hide()});
              }
              $("#tei-theme-words").hide("slow");
            }
        },

        scrollTo: function(a_elem) {
          console.log($(a_elem).text());
          console.log("Postion: " + $(a_elem).position().top);
          console.log("Top: " + $(a_elem).offset().top);
          return $(a_elem).position().top - $(a_elem).height();
        },
        
        findCite: function(a_urn,a_callback) {
            $.get("http://services.perseids.org/cite_mapper/find_cite?cite=" + a_urn, a_callback, "json");
        }

        
    };

    window.teilod = teilod;
})(window);
