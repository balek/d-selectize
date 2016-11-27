_ = require 'lodash'


module.exports = class
    view: __dirname
    components: [
        class extends require('d-form').DField
            name: 'field'
#            init: ->
#                super()
#                @model.set 'errors.invalid', 'value', (value) =>
#                    if value and not _.some @selectize.options, [config.valueField or 'value', value]
    ]

    create: ->
        $ = require 'jquery'
        require 'selectize'

        options = @getAttribute 'options'
        config = @model.getDeepCopy('config') or {}
        if not config?.buildOption
            config.buildOption = (x) ->
                x.value = '' if not x.value
                x
        config.buildOptions = (o) -> _.map o, config.buildOption
        options = config.buildOptions options
        $(@elem).selectize _.defaults {}, config,
            items: null
            optgroups: @getAttribute 'optgroups'
            options: options
            onChange: (value) =>
                if value
                    @savedValue = undefined
                if @selectize.settings.mode == 'single'
                    value ||= undefined
                @model.setDiff 'value', value
                @emit 'change', value
                
            onBlur: =>
                if @selectize.getValue() == ''
                    # Set default text on blur
                    @selectize.setValue '', true
                    
        @selectize = $(@elem)[0].selectize

        @model.on 'change', 'value', (value) =>
#                @selectize.clear true
#                if not _.isArray value
#                    value = [value]
#                for i in value
#                    @selectize.addItem i, true
            if @selectize.settings.mode == 'single'
                value ?= ''
            # Prevent setting default text on clear
            if value != @selectize.getValue()
                @selectize.setValue value, true


        value = @model.get 'value'
        @savedValue = value
        value ?= ''
        @selectize.setValue value, true
        @selectize.updateOriginalInput() if not config.asyncOptions
        
        


        @model.on 'change', 'options', (options = []) =>
            # Можно использовать этот обработчик для всех событий ('all'), но тогда значение в поле будет исчезать и снова появляться
            @savedValue ||= @model.get 'value'
            options = config.buildOptions options

            @selectize.clear true
            @selectize.clearOptions()
            for option in options
                @selectize.addOption option

            if @savedValue
                @selectize.setValue @savedValue
                @selectize.updateOriginalInput()

        @model.on 'insert', 'options', (position, options) =>
            options = config.buildOptions options
            for option in options
                @selectize.addOption option
            if @savedValue
                @selectize.setValue @savedValue  # Нужно для установки выбранного значения при загрузке страницы

        @model.on 'remove', 'options', (position, options) =>
            options = config.buildOptions options
            for option in options
                @selectize.removeOption option[config.valueField or 'value']

        @on 'destroy', ->
            eventNS = @selectize.eventNS

            @selectize.trigger 'destroy'
            @selectize.off()
            @selectize.$input.removeData 'selectize'

            $(window).off eventNS
            $(document).off eventNS
            $(document.body).off eventNS

            delete @selectize.$input[0].selectize
