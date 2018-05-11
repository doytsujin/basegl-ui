import * as basegl    from 'basegl'
import * as Animation from 'basegl/animation/Animation'
import * as Easing    from 'basegl/animation/Easing'
import * as Color     from 'basegl/display/Color'
import {world}        from 'basegl/display/World'
import {circle, glslShape, union, grow, negate, rect, quadraticCurve} from 'basegl/display/Shape'
import {Composable, fieldMixin} from "basegl/object/Property"

import {InPort, OutPort} from 'view/Port'
import {Component}       from 'view/Component'
import * as shape        from 'shape/Visualization'
import * as util         from 'shape/util'
import * as nodeShape    from 'shape/Node'
import {Widget}          from 'view/Widget'
import * as style        from 'style'
import * as path         from 'path'

import * as _ from 'underscore'


visualizationShape = basegl.symbol shape.visualizationShape

export class NodeVisualizations extends Component
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
                    newVis.attach()

            for own key of @visualizations
                unless newVisualizations[key]?
                    @visualizations[key].dispose()

            @visualizations = newVisualizations

    dispose: =>
        for own key of @visualizations
           @visualizations[key].dispose()

    getPosition: =>
        node = @parent.node @nodeKey
        offset = if node.expanded
                [ nodeShape.width/2
                , - node.bodyHeight - nodeShape.height/2 - nodeShape.slope ]
            else [ 0, - nodeShape.height/2 ]

        return [ node.position[0] + offset[0]
            , node.position[1] + offset[1]]


    updateVisualizationsPositions: =>
        pos = @getPosition()
        for own key of @visualizations
            @visualizations[key].set position: pos

    registerEvents: =>
        node = @parent.node @nodeKey
        @addDisposableListener node, 'position', => @updateVisualizationsPositions()
        @addDisposableListener node, 'expanded', => @updateVisualizationsPositions()

export class VisualizationContainer extends Widget
    constructor: (args...) ->
        super args...
        @configure
            height: 300
            width:  300

    updateModel: ({ key:                @key                = @key
                  , iframeId:            iframeId           = @iframeId
                  , mode:                mode               = @mode
                  , currentVisualizer:   currentVisualizer  = @currentVisualizer
                  , selectedVisualizer:  selectedVisualizer = @selectedVisualizer
                  , visualizers:         visualizers        = @visualizers
                  , position:            position           = @position or [0,0] }) =>
        if @iframeId != iframeId or @position != position or @mode != mode or not _.isEqual(@currentVisualizer, currentVisualizer)
            @iframeId          = iframeId
            @mode              = mode
            @currentVisualizer = currentVisualizer
            @position          = position
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
                vis.attach()

            unless @def?
                root = document.createElement 'div'
                root.id           = @key
                root.style.width  = @width + 'px'
                root.style.height = @height + 'px'
                @def = basegl.symbol root
            if @view?
                @reattach

        if @mode != mode or @selectedVisualizer != selectedVisualizer or @visualizers != visualizers
            @mode               = mode
            @selectedVisualizer = selectedVisualizer
            @visualizers        = visualizers
            #  if @visualizerMenu?
            #     @visualizerMenu.set vis
            # else
            #     vis = new VisualizationMenu vis, @
            #     @visualizerMenu = vis
            #     vis.attach()

            # unless @def?
            #     root = document.createElement 'div'
            #     root.id = @key
            #     root.style.width = 200 + 'px'
            #     root.style.height = 300 + 'px'
            #     root.style.backgroundColor = '#FF0000'
            #     @def = basegl.symbol root
            # if @view?
            #     @reattach


    updateView: =>
        @view.domElement.className = style.luna ['visualization-container']
        @group.position.xy = [@position[0], @position[1] - @height/2]

    dispose: =>
        @visualization.dispose()
        
    # renderVisualizerMenu: =>
    #     container = document.createElement 'div'
    #     container.className = style.luna ['dropdown']
    #     menu = document.createElement 'ul'
    #     menu.className = style.luna ['dropdown__menu']

    #     for visualizer in @visualizers
    #         menu.appendChild (@renderVisualizerMenuEntry visualizer)

    #     container.appendChild menu
    #     return container

    # renderVisualizerMenuEntry: (visualizer) =>
    #     entry = document.createElement 'li'
    #     entry.appendChild document.createTextNode visualizer.visualizerName
    #     return entry

export class Visualization extends Widget
    constructor: (args...) ->
        super args...
        @configure
            height: 300
            width:  300

    updateModel: ({ key:                @key                = @key
                  , iframeId:            iframeId           = @iframeId
                  , mode:                mode               = @mode
                  , currentVisualizer:   currentVisualizer  = @currentVisualizer
                  , position:            position           = @position or [0,0] }) =>
        @rerender = false
        if @position != position
            @position = position
        if @iframeId != iframeId or @mode != mode or not _.isEqual(@currentVisualizer, currentVisualizer)
            @iframeId          = iframeId
            @mode              = mode
            @currentVisualizer = currentVisualizer
            @rerender          = true
        unless @def?
            root = document.createElement 'div'
            root.id           = @key
            root.style.width  = @width + 'px'
            root.style.height = @height + 'px'
            @def = basegl.symbol root    
        if @view?
            @reattach

    updateView: =>
        @group.position.xy = [@position[0], @position[1] - @height/2]
        if @rerender
            @view.domElement.innerHTML = ''
            @view.domElement.appendChild @renderVisualization()

    renderVisualization: =>
        iframe = document.createElement 'iframe'
        visPaths = @parent.parent.parent.visualizerLibraries
        visType = @currentVisualizer.visualizerType
        pathPrefix = if visType == 'InternalVisualizer'
                visPaths.internalVisualizersPath
            else if visType == 'LunaVisualizer'
                visPaths.lunaVisualizersPath
            else visPaths.projectVisualizersPath
        if pathPrefix?
            url = path.join pathPrefix, @currentVisualizer.visualizerPath
            # url = 'https://onet.pl'
            iframe.name         = @iframeId
            iframe.style.width  = @width + 'px'
            iframe.style.height = @height + 'px'
            iframe.className    = style.luna ['visualization-iframe']
            iframe.src          = url
        return iframe