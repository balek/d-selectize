_ = require 'lodash'


module.exports = class
    view: __dirname
    components: [
        class extends require('d-form').DField
            name: 'field'
    ]

    create: ->
        $ = require 'jquery'
        require 'selectize'

        options = @getAttribute 'options'
        config = @model.getDeepCopy('config') or {}
        if not config?.buildOption
            config.buildOption = (x) ->
                x.value = 'undefined' if not x.value
                x
        config.buildOptions = (o) -> _.map o, config.buildOption
        options = config.buildOptions options
        $(@elem).selectize _.defaults {}, config,
            items: null
            plugins: ['restore_on_backspace', 'remove_button']
            optgroups: @getAttribute 'optgroups'
            options: options
            onChange: (value) =>
                if value
                    @savedValue = undefined
                value = undefined if value == 'undefined'
                @model.setDiff 'value', value
                @emit 'change', value
        @selectize = $(@elem)[0].selectize

        @model.on 'change', 'value', (value) =>
#                @selectize.clear true
#                if not _.isArray value
#                    value = [value]
#                for i in value
#                    @selectize.addItem i, true
            if not value
                options = @getAttribute 'options'
                options = config.buildOptions options
                if _.some(options, value: undefined)
                    value = 'undefined'
                else
                    value = _.find(options, 'default')?.value
            @selectize.setValue value, true


        value = @model.get 'value'
        if value
            @savedValue = value
            @selectize.setValue value
            @selectize.updateOriginalInput() if not config.asyncOptions
        else
            for option in options or []
                if option.default
                    @selectize.setValue option.value
                    break


        @model.on 'change', 'options', (options = []) =>
            # Можно использовать этот обработчик для всех событий ('all'), но тогда значение в поле будет исчезать и снова появляться
            if not @savedValue
                @savedValue = @model.get 'value'
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
            @selectize.destroy()
