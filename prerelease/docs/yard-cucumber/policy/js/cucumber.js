function cucumberKeyboardShortcuts() {
  if (window.top.frames.main) return;
  $(document).keypress(function(evt) {
    if (evt.altKey || evt.ctrlKey || evt.metaKey || evt.shiftKey) return;
    if (typeof evt.target !== "undefined" &&
        (evt.target.nodeName == "INPUT" ||
        evt.target.nodeName == "TEXTAREA")) return;
    switch (evt.charCode) {
      case 68: case 100: $('#stepdefinition_list_link').click(); break;  // 'd'
      case 82: case 114: $('#feature_list_link').click(); break; // 'r'
      case 83: case 115: $('#step_list_link').click(); break; // 's'
      case 84: case 116: $('#tag_list_link').click(); break;  // 't'
    }
  });
}

$(cucumberKeyboardShortcuts);

$(function() {

    //
    //  Feature Page - Scenarios 
    //
    $('.scenario div.title').click(function(eventObject) {
        if (typeof eventObject.currentTarget !== "undefined")  {
            toggleScenario( $($(eventObject.currentTarget).parent()) );
        }
    });

    //
    // Developer View
    // Click + Developer View = toggle the expansion of all tags, location, and comments
    //
    $('#view').click(function(eventObject) {
		
        if (typeof eventObject.currentTarget !== "undefined")  {
            var view = eventObject.currentTarget;
			
            if (view.innerHTML === '[More Detail]') {
                $('.developer').show(500);
                view.innerHTML = '[Less Detail]';
            } else {
                $('.developer').hide(500);
                // Already hidden elements with .developer sub-elements were not getting message
                $('.developer').each(function() {
                    $(this).css('display','none');
                });
                view.innerHTML = '[More Detail]';
            }
        }
    });

    //
    // Expand/Collapse All
    //
    $('#expand').click(function(eventObject) {
	    
        if (typeof eventObject.currentTarget !== "undefined")  {
            if (eventObject.currentTarget.innerHTML === '[Expand All]') {
                eventObject.currentTarget.innerHTML = '[Collapse All]';
                $('div.scenario > div.details:hidden').each(function() {
                    toggleScenario( $($(this).parent()) );
                });
            } else {
                eventObject.currentTarget.innerHTML = '[Expand All]';
                $('div.scenario > div.details:visible').each(function() {
                    toggleScenario( $($(this).parent()) );
                });
            }
        }
    });

    //
    // Expand/Collapse All
    //
    $('#stepdefinition,#steptransform').click(function(eventObject) {

        if (typeof eventObject.currentTarget !== "undefined")  {
            if (eventObject.currentTarget.innerHTML === '[Expand All]') {
                eventObject.currentTarget.innerHTML = '[Collapse All]';
                $('div.' + eventObject.currentTarget.id + ' > div.details:hidden').each(function() {
                    $(this).show(200);
                });
            } else {
                eventObject.currentTarget.innerHTML = '[Expand All]';
                $('div.' + eventObject.currentTarget.id + ' > div.details:visible').each(function() {
                    $(this).hide(200);
                });
            }
        }
    });


    //
    // Scenario Outlines - Toggle Examples
    //
    $('.outline table tr').click(function(eventObject) {
		
        if (typeof eventObject.currentTarget !== "undefined")  {
            var exampleRow = $(eventObject.currentTarget);
            
            if (eventObject.currentTarget.className.match(/example\d+-\d+/) == null) {
                return false;
            }
            
            var exampleClass = eventObject.currentTarget.className.match(/example\d+-\d+/)[0];
            var example = exampleRow.closest('div.details').find('.' + exampleClass);
			
            var currentExample = null;
			
            $('.outline table tr').each(function() {
                $(this).removeClass('selected');
            });
			
            if ( example[0].style.display == 'none' ) {
                currentExample = example[0];
                exampleRow.addClass('selected');
            } else {
                currentExample = exampleRow.closest('div.details').find('.steps')[0];
            }

            // hide everything
            exampleRow.closest('div.details').find('.steps').each(function() {
                $(this).hide();
            });
			
            // show the selected
            $(currentExample).show();
        }
    });


});
 

function toggleScenario(scenario) {
	
    var state = scenario.find(".attributes input[name='collapsed']")[0];
	
    if (state.value === 'true') {
        scenario.find("div.details").each(function() {
            $(this).show(500);
        });
        state.value = "false";
        scenario.find('a.toggle').each(function() {
            this.innerHTML = ' - ';
        });
		
    } else {
        scenario.find("div.details").each(function() {
            $(this).hide(500);
        });
        state.value = "true";
        scenario.find('a.toggle').each(function() {
            this.innerHTML = ' + ';
        });
    }
}


function updateTagFiltering(tagString) {
    var formulaTags = determineTagsUsedInFormula(tagString);
    displayExampleCommandLine(formulaTags);
    displayQualifyingFeaturesAndScenarios(formulaTags);
    fixSectionRowAlternations();
}

function clearTagFiltering() {
    updateTagFiltering("");
}

function determineTagsUsedInFormula(tagString)  {

    tagString = tagString.replace(/^(\s+)|(\s+)$/,'').replace(/\s{2,}/,' ');

    var tagGroup = tagString.match(/(?:~)?@\w+(,(?:~)?@\w+)*/g);

    var returnTags = [];

    if (tagGroup) {
        tagGroup.forEach(function(tag, index, array) {
            console.log("Tag Group: " + tag);
            var validTags = removeInvalidTags(tag)
            if (validTags != "") {
                returnTags.push(validTags);
            }
        });
    }

    return returnTags;
}

function removeInvalidTags(tagGroup) {
    tagGroup.split(",").forEach(function(tag, index, array) {
        
        baseTag = tag.match(/^~(.+)/) ? tag.match(/^~(.+)/)[1] : tag;
        
        //console.log("Validating Tag: " + tag)
        if (tag_list.indexOf(baseTag) === -1) {
            //console.log("Removing Tag: " + tag);
            tagGroup = tagGroup.replace(new RegExp(',?' + tag + ',?'),"")
        }
    });

    return tagGroup;
}


function displayExampleCommandLine(tags) {
    $("#command_example")[0].innerHTML = "cucumber ";

    if (tags.length > 0)  {
        $("#command_example")[0].innerHTML += "--tags " + tags.join(" --tags ");
    }
}

function fixSectionRowAlternations() {
    $(".feature:visible,.scenario:visible").each(function(index){
        $(this).removeClass("odd even").addClass( ((index + 1) % 2 == 0 ? "even" : "odd") );
    });
}

function displayQualifyingFeaturesAndScenarios(tags) {

    if (tags.length > 0) {

        $(".feature,.scenario").each(function(feature){
            $(this).hide();
        });

        var tagSelectors = generateCssSelectorFromTags(tags);

        tagSelectors.forEach(function(selector,selectorIndex,selectorArray) {
            var tags = selector;
            
            $(".feature." + tags).each(function(index) {
                $(this).show();
            });
            $(".scenario." + tags).each(function(index) {
                $(this).show();
                $(this).parent().prev().show();
            });
            
        });
        
        if ( $(".feature:visible,.scenario:visible").length == 0 ) {
            $("#features div.undefined").show();
        }  else {
            $("#features div.undefined").hide();
        }
        

    } else {
        $(".feature:hidden,.scenario:hidden").each(function(feature){
            $(this).show();
        });
    }

}

function generateCssSelectorFromTags(tagGroups) {

    var tagSelectors = [ "" ];

    tagGroups.forEach(function(tagGroup,index,array) {
        var newTagSelectors = [];

        tagSelectors.forEach(function(selector,selectorIndex,selectorArray) {
            tagGroup.split(",").forEach(function(tag,tagIndex,tagArray) {
                
                if ( tag.match(/^~@.+$/) ) {
                    tag = tag.match(/^~(@.+)$/)[1]
                    //console.log("selector: " + (selector + " :not(" + tag + ")").trim());
                    newTagSelectors.push((selector + ":not(." + tag.replace(/@/g,"\\@") +")").trim());
                } else { 
                    //console.log("selector: " + (selector + " " + tag).trim());
                    newTagSelectors.push((selector + "." + tag.replace(/@/g,"\\@")).trim());
                }
            });

        });

        tagSelectors = newTagSelectors;

    });


    return tagSelectors;
}


function createStepDefinitionLinks() {
    // $('.step_instances_list').
    //         before("<span class='showSteps'>[<a href='#' class='toggleSteps'>View steps</a>]</span>");
    $('.toggleSteps').toggle(function() {
        $(this).parent().next().slideUp(100);
        $(this).text("View " + $(this).attr('alt'));
    },
    function() {
        $(this).parent().next().slideDown(100);
        $(this).text("Hide " + $(this).attr('alt'));
    });
}

$(createStepDefinitionLinks);
