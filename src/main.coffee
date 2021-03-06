require 'babel-core/register'
require 'babel-polyfill'
import * as basegl from 'basegl'

import {Breadcrumb}         from 'view/Breadcrumb'
import {Connection}         from 'view/Connection'
import {HalfConnection}     from 'view/HalfConnection'
import {ExpressionNode}     from 'view/ExpressionNode'
import {subscribeEvents}    from 'abstract/EventEmitter'
import {InputNode}          from 'view/InputNode'
import {NodeEditor}         from 'view/NodeEditor'
import {OutputNode}         from 'view/OutputNode'
import {runPerformance}     from './performance'
import * as layers          from 'view/layers'
import * as test            from './test'

removeChildren = (name) =>
    element = document.getElementById(name)
    unless element?
        console.error "The DOM element \"#{name}\" does not exist."
        return

    element.innerHTML = ''
    while element.firstChild
        element.removeChild element.firstChild

export install = (name, fontRootPath = '', keyboard, callback) ->
    removeChildren name
    scene = basegl.scene {domElement: name}
    basegl.fontManager.register 'SourceCodePro', fontRootPath + 'SourceCodeVariable-Roman.ttf'
    basegl.fontManager.load('SourceCodePro').then (atlas) =>
        atlas._letterDef.defaultZIndex = layers.text
        nodeEditor = new NodeEditor scene, name, keyboard
        window.n = nodeEditor
        callback nodeEditor

export onEvent = subscribeEvents

main = (callback) -> install 'node-editor-mount', 'rsc/', callback

runExample = -> main (nodeEditor) ->
    nodeEditor.setBreadcrumb
        moduleName: 'Foo'
        items:
            [
                name: 'bar'
                breadcrumb: 1
            ,
                name: 'baz'
                breadcrumb: 2
            ]

    nodeEditor.setNodes [
            key: 1
            name: 'number1'
            expression: '12'
            newPortKey: 'new'
            inPorts:
                1:
                    name: 'onlyPort'
                    typeName: 'Int'
            outPorts:
                1:
                    typeName: 'A'
                2:
                    typeName: 'B'
            icon: 'rect'
            position: [200, 600]
            expanded: false
            selected: false
            # error: true
            # value:
            #     tag: 'Error'
            #     contents:
            #         tag: 'ShortValue'
            #         contents: 'Another error description'
        ,
            key: 2
            name: 'bar2'
            expression: '54'
            inPorts:
                0:
                    name: 'self'
                    mode: 'self'
                    typeName: 'A'
                1:
                    name: 'port1'
                    typeName: 'A'
                2:
                    name: 'port2'
                    typeName: 'A'
                3:
                    name: 'port3'
                    typeName: 'A'
                4:
                    name: 'port4'
                    typeName: 'B'
            outPorts:
                1:
                    typeName: 'A'
            icon: 'rect'
            position: [300, 300]
            expanded: false
            selected: false
            value:
                tag: 'Value'
                contents:
                    tag: 'Visualization'
        ,
            key: 3
            name: 'baz3'
            expression: 'foo bar baz'
            newPortKey: 'new'
            inPorts:
                0:
                    name: 'self'
                    mode: 'self'
                    typeName: 'A'
                1:
                    name: 'port1'
                    typeName: 'B'
                2:
                    name: 'port2'
                    typeName: 'C'
                3:
                    name: 'port3'
                    typeName: 'D'
                4:
                    name: 'port4'
                    typeName: 'E'
                5:
                    name: 'port5'
                    typeName: 'F'
                6:
                    name: 'port6'
                    typeName: 'G'
            outPorts:
                1: {}
            controls:
                'a':
                    controls:
                        [
                            cls: 'Int'
                            min: 0
                            max: 100
                            value: 49
                        ]
                1:
                    controls:
                        [
                            cls: 'Int'
                            min: 0
                            max: 100
                            value: 49
                        ,
                            cls: 'Bool'
                            value: true
                        ,
                            cls: 'Bool'
                            value: false
                        ]
                2:
                    controls:
                        [
                            cls: 'Real'
                            min: -10
                            max: 10
                            value: 5
                        ]
                3:
                    controls:
                        [
                            cls: 'Text'
                            value: 'test'
                        ,
                            cls: 'Int'
                            min: -10
                            max: 10
                            value: 5
                        ,
                            cls: 'Int'
                            min: -10
                            max: 10
                            value: 5
                        ]
                4:
                    controls:
                        [
                            cls: 'Text'
                            value: 'test2'
                        ]
                5:
                    controls:
                        [
                            cls: 'Bool'
                            value: true
                        ]
                6:
                    controls:
                        [
                            cls: 'Real'
                            min: -10
                            max: 10
                            value: 5
                        ]

            icon: 'stripes'
            position: [600, 500]
            expanded: true
            selected: false
        ,
            key: 4
            name: 'node4'
            inPorts:
                1:
                    name: 'ooo'
                    typeName: 'A'
            outPorts:
                1: {}
            icon: 'stripes'
            position: [800, 500]
            expanded: false
            selected: false
        ]

    nodeEditor.setInputNode
        key: 'in'
        outPorts:
            1:
                name: 'a'
            2:
                name: 'b'
            3:
                name: 'c'
    nodeEditor.setOutputNode
        key: 'out'
        inPorts:
            1:
                name: 'output1'
                color: [0, 0.5, 0.5]
            2:
                name: 'output2'
                color: [0.2, 0.5, 0.3]
    nodeEditor.setConnections [
            key: 0
            srcNode: 'in'
            srcPort: 2
            dstNode: 1
            dstPort: 1
        ,
            key: 1
            srcNode: 1
            srcPort: 1
            dstNode: 2
            dstPort: 0
        ,
            key: 2
            srcNode: 2
            srcPort: 1
            dstNode: 3
            dstPort: 1
        ,
            key: 3
            srcNode: 3
            srcPort: 1
            dstNode: 4
            dstPort: 1
        ,
            key: 4
            srcNode: 4
            srcPort: 1
            dstNode: 'out'
            dstPort: 2
        ,
            key: 5
            srcNode: 1
            srcPort: 2
            dstNode: 3
            dstPort: 0
        ,
            key: 6
            srcNode: 1
            srcPort: 1
            dstNode: 4
            dstPort: 1
        ]

    nodeEditor.setVisualizerLibraries
        internalVisualizersPath: ''
        lunaVisualizersPath:     ''
        projectVisualizersPath:  ''


    nodeEditor.setVisualization
        nodeKey: 2
        visualizers: [
            {visualizerName: 'base: json', visualizerType: 'LunaVisualizer'},
            {visualizerName: 'base: yaml', visualizerType: 'LunaVisualizer'}
        ]
        visualizations: [
            key: 900
            currentVisualizer:
                visualizerId:
                    visualizerName: 'base: json'
                    visualizerType: 'LunaVisualizer'
                visualizerPath: 'base/json/json.html'
            iframeId: '1'
            mode: 'Default'
            selectedVisualizer:
                visualizerName: 'base: json'
                visualizerType: 'LunaVisualizer'
        ]
    
    nodeEditor.setVisualization
        nodeKey: 3
        visualizers: []
        visualizations: [
            key: 901
            currentVisualizer:
                visualizerId:
                    visualizerName: 'internal: error'
                    visualizerType: '"InternalVisualizer"'
                visualizerPath: '"internal/error/error.html"'
            iframeId: '2'
            mode: 'Default'
            selectedVisualizer:
                visualizerName: 'base: json'
                visualizerType: 'LunaVisualizer'
        ]
    nodeEditor.setSearcher
        key: 3
        entries: [
            name: 'foo'
        ,
            name: 'bar'
        ,
            name: 'baz'
        ,
            name: 'a very long hint'
        ]


    # nodeEditor.setHalfConnections [
    #         srcNode: 1
    #         srcPort: 1
    #         reversed: false
    #     ]

    subscribeEvents (path, event, key) =>
        console.log path.join('.'), event, key
        if event.tag == 'FocusVisualizationEvent'
            nodeKey = path[2]
            nodeEditor.setVisualization
                nodeKey: nodeKey
                visualizations: [
                    key: 900
                    mode: 'Focused'
                ]
        if event.tag == 'MouseEvent' and event.type == 'mouseup'
            nodeEditor.setVisualization
                nodeKey: 2
                visualizations: [
                    key: 900
                    mode: 'Default'
                ]
            nodeEditor.setVisualization
                nodeKey: 3
                visualizations: [
                    key: 901
                    mode: 'Default'
                ]

if NODE_EDITOR_EXAMPLE? then runExample()
else if NODE_EDITOR_PERFORMANCE? then main runPerformance
else if NODE_EDITOR_TEST? then test.main()
