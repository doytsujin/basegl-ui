import {HasModel}     from "abstract/HasModel"
import * as basegl    from 'basegl/display/Symbol'
import * as animation from 'shape/Animation'


export class BasicComponent extends HasModel
    __draw: (def) =>
        unless @__element?
            @__element = @root.scene.add def
            @__addToGroup @__element

    __undraw: =>
        if @__element?
            @__removeFromGroup @__element
            @__element.dispose()
            @__element = null

    onModelUpdate: =>
        if (@redefineRequired? and @redefineRequired(@changed)) or @changed.once
            def = @define()
            if def?
                @__undraw()
                @__draw def
                @__def = def
        if @__element?
            if @changed.once
                @adjustSrc? @__element, @__view
            @adjust? @__element, @__view

    dispose: =>
        if @__element?
            if @adjustDst?
                @adjustDst? @__element, @__view
            else
                @adjustSrc? @__element, @__view
        @__undraw @__def
        if @__view
            @__view.dispose()
            @__view = null
        super()

    getElement: => @__element

    animateVariable: (name, value, animate = true) =>
        if animate
            animation.animate @style, @__element, 'variables', name, value
        else
            @__element.variables[name] = value

    # # implement following methods when deriving: #
    # ##############################################
    #
    # initModel: =>
    #     # return model structure (optional, default: {})
    #
    # prepare: =>
    #     # predefine shapes (optional)
    #
    # redefineRequired (values) =>
    #     # test values if it is required to redefine shape (optional, default: false)
    #
    # define =>
    #     # use @values to create def and return it
    #     ...
    #     return def
    #
    # registerEvents: (element) =>
    #     # register events on element being group of all defs (optional)
    #
    # connectSources =>
    #     connect sources of data for component
    #
    # adjust (element, view) => #TODO think about renaming to onNewModel
    #     # use @values to adjust element and view
    #     ...
    #     element.rotation = @values.angle
    #     ...

export memoizedSymbol = (symbolFun) =>
    lastRevision = null
    cachedSymbol = null
    return (style) =>
        unless lastRevision == style.revision
            lastRevision = style.revision
            cachedSymbol = symbolFun style
        return cachedSymbol
