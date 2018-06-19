import * as path      from 'path'
import * as _         from 'underscore'
import * as basegl    from 'basegl'
import * as style     from 'style'
import * as nodeShape from 'shape/Node'
import * as shape     from 'shape/Visualization'

import {group}                from 'basegl/display/Symbol'
import {Component, pushEvent} from 'view/Component'
import {Widget}               from 'view/Widget'

export visualizationCover = basegl.symbol shape.visualizationCoverShape
menuToggler               = basegl.symbol shape.menuTogglerDiv
visualization             = basegl.symbol shape.visualizationDiv

export class NodeVisualizations extends Component
    cons: (values, @parent) =>
        @nodeEditor = @parent
        super values, @parent

    updateModel: ({ nodeKey:        @nodeKey            = @nodeKey
                  , visualizers:     visualizers        = @visualizers
                  , visualizations:  visualizations }) =>
        if not _.isEqual(visualizers, @visualizers)
            @visualizers = visualizers
        if visualizations?
            @visualizations ?= {}
            pos = @getPosition()
            newVisualizations = {}

            for vis in visualizations
                vis.visualizers = @visualizers
                vis.position    = pos
                if @visualizations[vis.key]?
                    newVisualizations[vis.key] = @visualizations[vis.key]
                    newVisualizations[vis.key].set vis
                else
                    newVis = new VisualizationContainer vis, @
                    newVisualizations[vis.key] = newVis

            for own key of @visualizations
                unless newVisualizations[key]?
                    @visualizations[key].dispose()

            @visualizations = newVisualizations

    dispose: =>
        for own k,v of @visualizations
           v.dispose()

    getPosition: =>
        node = @nodeEditor.node @nodeKey
        offset = if node.expanded
                [ nodeShape.width/2
                , - node.bodyHeight - nodeShape.height/2 - nodeShape.slope - nodeShape.togglerSize ]
            else [ 0, - nodeShape.height/2 - nodeShape.togglerSize]

        return [ node.position[0] + offset[0]
            , node.position[1] + offset[1]]


    updateVisualizationsPositions: =>
        pos = @getPosition()
        for own key of @visualizations
            @visualizations[key].set position: pos

    registerEvents: =>
        node = @nodeEditor.node @nodeKey
        @addDisposableListener node, 'position', => @updateVisualizationsPositions()
        @addDisposableListener node, 'expanded', => @updateVisualizationsPositions()

    eventPath: =>
        nePath = @nodeEditor.eventPath?() or [@nodeEditor.constructor.name]
        nePath.concat ["NodeVisualization", @nodeKey]

export class VisualizationContainer extends Widget
    cons: (values, @parent) =>
        @nodeEditor = @parent.nodeEditor
        @def        = visualizationCover
        @configure
            minHeight: shape.height
            maxHeight: shape.height
            minWidth:  shape.width
            maxWidth:  shape.width
        super values, @parent

    updateModel: ({ key:                @key                = @key
                  , iframeId:            iframeId           = @iframeId
                  , mode:                mode               = @mode
                  , currentVisualizer:   currentVisualizer  = @currentVisualizer
                  , selectedVisualizer:  selectedVisualizer = @selectedVisualizer
                  , visualizers:         visualizers        = @visualizers
                  , position:            position           = @position or [0,0] }) =>
        @position           = position
        @iframeId           = iframeId
        @mode               = mode
        @currentVisualizer  = currentVisualizer
        @selectedVisualizer = selectedVisualizer
        @visualizers        = visualizers

        unless @view?
            @attach()

        @updateVisualization()
        @updateVisualizerMenu()


    updateVisualization: =>
        vis = {
            key: @key,
            iframeId: @iframeId,
            mode: @mode,
            currentVisualizer: @currentVisualizer,
            position: @position
        }
        if @visualization?
            @visualization.set vis
        else
            vis = new Visualization vis, @
            @visualization = vis

    updateVisualizerMenu: =>
        if @visualizers?.length
            vm = {
                key: @key,
                mode: @mode,
                visualizers: @visualizers,
                visualizer: @selectedVisualizer,
                position: @position
            }
            if @visualizerMenu?
                @visualizerMenu.set vm
            else
                vm = new VisualizerMenu vm, @
                @visualizerMenu = vm
        else @visualizerMenu?.dispose()

    updateView: =>
        @group.position.xy = [ 
            @position[0] - shape.width/2,
            @position[1] - @height ]
        @view.bbox.xy = [shape.width, @height]

    dispose: =>
        super()
        @visualization?.dispose()
        @visualizerMenu?.dispose()
    
    eventPath: =>
        evtPath = @parent.eventPath()
        evtPath.push @key
        evtPath

    pushFocusVisualization: => 
        @pushEvent
            tag: 'FocusVisualizationEvent'

    registerEvents: =>
        @group.addEventListener 'click', =>
            if @mode == 'Default'
                @pushFocusVisualization()

export class Visualization extends Widget
    cons: (values, @parent) =>
        @nodeEditor  = @parent.nodeEditor
        @configure
            minHeight: @parent.minHeight
            maxHeight: @parent.maxHeight
            minWidth:  @parent.minWidth
            maxWidth:  @parent.maxWidth
        super values, @parent
        @registerEvents()

    eventPath: =>
        @parent.eventPath()

    registerEvents: =>
        @addDisposableListener @nodeEditor, 'visualizerLibraries', => @updateIframe()

    updateModel: ({ key:                @key                = @key
                  , iframeId:            iframeId           = @iframeId
                  , mode:                mode               = @mode
                  , currentVisualizer:   currentVisualizer  = @currentVisualizer
                  , position:            position           = @position or [0,0] }) =>

        @position = position
        
        if @iframeId != iframeId or
        not _.isEqual(@currentVisualizer, currentVisualizer)
            @iframeId          = iframeId
            @currentVisualizer = currentVisualizer
            @mode              = mode
            @updateIframe()

        if @mode != mode
            @mode = mode
            @updateMode()
    
    updateIframe: =>
        iframe = @__mkIframe()

        if iframe?
            unless @view?
                @attach()
            while @view.domElement.hasChildNodes()
                @view.domElement.removeChild @view.domElement.firstChild
            @view.domElement.appendChild iframe
        else if @view?
            @_detach()

        @updateMode()


    # FIXME: This function is needed due to bug in basegl or THREE.js
    # which causes problems with positioning when layer changed
    __forceUpdatePosition: =>
        if @view?
            if @view.position.y == 0 
                @view.position.y = 1
            else
                @view.position.y = 0

    updateMode: => @withScene (scene) =>
        if @view?
            if @mode == 'Default'
                @view.domElement.className = style.luna ['basegl-visualization']
                scene.domModel.model.add @view.obj
            else if @mode == 'Focused'
                @view.domElement.className = style.luna ['basegl-visualization']
                @nodeEditor.domScene.model.add @view.obj
            else
                @view.domElement.className = style.luna ['basegl-visualization--fullscreen']
                @nodeEditor.domSceneNoScale.model.add @view.obj
                @__forceUpdatePosition()

    updateView: => @withScene (scene) =>
        if @mode == 'Default' or @mode == 'Focused'
            @group?.position.xy = [@position[0], @position[1] - @height/2]
        else
            @group?.position.xy = [scene.width/2, scene.height/2]
        
    _detach: =>
        while @view.domElement.hasChildNodes()
            @view.domElement.removeChild @view.domElement.firstChild
        super()

    attach: =>
        @view = visualization.newInstance()
        @view.domElement.id = @key
        @group = group [@view]

    __mkIframe: =>
        if @currentVisualizer?
            visPaths = @nodeEditor.visualizerLibraries
            visType = @currentVisualizer.visualizerId.visualizerType
            pathPrefix = if visType == 'InternalVisualizer'
                    visPaths.internalVisualizersPath
                else if visType == 'LunaVisualizer'
                    visPaths.lunaVisualizersPath
                else visPaths.projectVisualizersPath
        
        if pathPrefix?
            url = path.join pathPrefix, @currentVisualizer.visualizerPath
                
        if url?
            iframe           = document.createElement 'iframe'
            iframe.name      = @iframeId
            iframe.className = style.luna ['basegl-visualization-iframe']
            iframe.src       = url
            iframe


export class VisualizerMenu extends Widget
    cons: (values, @parent) ->
        @nodeEditor = @parent.nodeEditor
        @configure
            minHeight: @parent.minHeight
            maxHeight: @parent.maxHeight
            minWidth:  @parent.minWidth
            maxWidth:  @parent.maxWidth
        super values, @parent

    eventPath: =>
        @parent.eventPath()

    updateModel: ({ key:                @key                = @key
                  , mode:                mode               = @mode
                  , visualizers:         visualizers        = @visualizers
                  , visualizer:          visualizer         = @visualizer
                  , position:            position           = @position or [0,0] }) =>
        @position = position

        if not _.isEqual(@visualizer, visualizer) or
        not _.isEqual(@visualizers, visualizers)
            @visualizers = visualizers
            @visualizer  = visualizer
            @updateMenu()

        if @mode != mode
            @mode = mode
            @updateMode()

        unless @view?
            @attach()

    updateMode: => @withScene (scene) =>
        if @view?
            if @mode == 'Default'
                @view.domElement.className = style.luna ['basegl-dropdown']
                @menu?.className = style.luna ['basegl-dropdown__menu']
                scene.domModel.model.add @view.obj
            else if @mode == 'Focused'
                @view.domElement.className = style.luna ['basegl-dropdown--top']
                @menu?.className = style.luna ['basegl-dropdown__menu']
                @nodeEditor.domScene.model.add @view.obj
            else
                @view.domElement.className = style.luna ['basegl-dropdown--fullscreen']
                @menu?.className = style.luna ['basegl-dropdown__menu--fullscreen']
                @nodeEditor.domSceneNoScale.model.add @view.obj
                @__forceUpdatePosition()

    updateMenu: =>
        if @view?
            @menu?.parentNode.removeChild @menu
            delete @menu
            @menu = @renderVisualizerMenu()
            @view.domElement.appendChild @menu

    updateView: => @withScene (scene) =>
        if @mode == 'Default' or @mode == 'Focused'
            @group?.position.xy = [@position[0] - @width/2 , @position[1]]
        else
            @group?.position.xy = [0, scene.height]

    _detach: =>
        while @view.domElement.hasChildNodes()
            @view.domElement.removeChild @view.domElement.firstChild
        super()

    attach: =>
        @view = menuToggler.newInstance()
        @view?.domElement.id = @key
        @group = group [@view]
        @updateMenu()
        @updateMode()

    # FIXME: This function is needed due to bug in basegl or THREE.js
    # which causes problems with positioning when layer changed
    __forceUpdatePosition: =>
        if @view?
            if @view.position.y == 0 
                @view.position.y = 1
            else
                @view.position.y = 0

    renderVisualizerMenu: =>
        menu = document.createElement 'ul'
        @visualizers.forEach (visualizer) =>
            entry = document.createElement 'li'
            if _.isEqual(visualizer, @visualizer)
                entry.className = style.luna ['basegl-dropdown__active']
            entry.addEventListener 'mouseup', => @pushEvent
                tag: 'SelectVisualizerEvent'
                visualizerId: visualizer
            entry.appendChild (document.createTextNode visualizer.visualizerName)
            menu.appendChild entry

        return menu
