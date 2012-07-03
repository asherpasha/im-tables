scope "intermine.query.tools", (exporting) ->

    ## Define stuff...

    TAB_HTML = _.template """
        <li>
            <a href="#<%= ref %>" data-toggle="tab">
                <%= title %>
            </a>
        </li>
    """

    PANE_HTML = _.template """
        <div class="tab-pane" id="<%= ref %>"></div>
    """

    exporting class Tools extends Backbone.View
        className: "im-query-tools"

        initialize: (@query) ->

        render: ->
            tabs = @make "ul",
                class: "nav nav-tabs"
            conf = [
                filters =
                    title: "Filters"
                    ref: "filters"
                    view: intermine.query.filters.Filters
                , columns =
                    title: "Columns"
                    ref: "columns"
                    view: intermine.query.columns.Columns
                , actions =
                    title: "Actions"
                    ref: "actions"
                    view: intermine.query.actions.Actions
            ]
            for c in conf
                $(tabs).append TAB_HTML(c)

            @$el.append tabs

            content = @make "div",
                class: "tab-content"

            for c in conf
                $pane = $(PANE_HTML(c)).appendTo content
                view = new c.view(@query)
                $pane.append view.render().el

            $(content).find('.tab-pane').first().addClass "active"
            $(tabs).find("a").first().tab 'show'

            @$el.append content

            this

    exporting class ToolBar extends Backbone.View

        className: "im-query-actionbar row-fluid"

        initialize: (@query) ->

        render: ->
            actions = new intermine.query.actions.ActionBar(@query)
            actions.render().$el.appendTo @el

            this

    class Step extends Backbone.View

        className: 'im-step'
        tagName: 'li'

        initialize: (opts) ->
            super(opts)
            @model.on 'got:count', (count) =>
                @$('.im-step-count .count').text intermine.utils.numToString count, ',', 3

            @model.on 'is:current', (isCurrent) =>
                @$('.btn').toggleClass('btn-inverse', not isCurrent).attr disabled: isCurrent
                @$('.btn-main').text if isCurrent then "Current State" else "Revert to this State"
                @$('.btn i').toggleClass('icon-white', not isCurrent)

            @model.on 'remove', () => @remove()

        events:
            'click h4': (e) ->
                $(e.target).find('i').toggleClass("icon-chevron-right icon-chevron-down")
                $(e.target).next().children().toggle()
            'click .btn': 'revertToThisState'

        revertToThisState: (e) ->
            @model.trigger 'revert', @model
            @$('.btn-small').tooltip('hide')

        render: () ->
            @$el.append """
                    <button class="btn btn-small im-state-revert" disabled
                        title="Revert to this state">
                        <i class=icon-undo></i>
                    </button>
                    <div>#{ @model.get 'title' }</div>
                    <span class="im-step-count"><span class="count"></span> rows</span>
                """

            @$('.btn-small').tooltip(placement: 'right')

            q = @model.get 'query'

            details = @$ '.im-step-details'

            addSection = (n, things) ->
                section = $ """
                        <div>
                            <h4>
                                <i class="icon-chevron-right"></i>
                                #{ n } #{ things }
                            </h4>
                            <ul></ul>
                        </div>
                    """
                section.appendTo details
                section.find 'ul'

            toLabel = (text, type) -> """<span class="label label-#{ type }">#{ text }</span>"""

            ps = (q.getPathInfo(v) for v in q.views)
            vlist = addSection(ps.length, 'Columns')
            for p in ps then do (p) ->
                li = $ '<li>'
                vlist.append li
                p.getDisplayName (name) -> li.append toLabel name, 'path'

            clist = addSection(q.constraints.length, 'Filters')
            for c in q.constraints then do (c) =>
                li = $ '<li>'
                clist.append li
                q.getPathInfo(c.path).getDisplayName (name) ->
                    li.append toLabel name, 'path'
                    li.append toLabel c.op, 'info'
                    if c.value?
                        li.append toLabel c.value, 'value'
                    else if c.values?
                        li.append toLabel c.values.join(', '), 'value'
            
            jlist = addSection _.size(q.joins), 'Joins'
            for path, style of q.joins then do (path, style) =>
                li = $ '<li>'
                jlist.append li
                q.getPathInfo(path).getDisplayName (name) ->
                    li.append toLabel name, 'path'
                    li.append toLabel style, 'info'
            this

    exporting class Trail extends Backbone.View
        
        className: "im-query-trail"
        tagName: "div"

        events:
            'click a.details': 'minumaximise'
            'click a.shade': 'toggle'

        toggle: () ->
            @$('.im-step').slideToggle 'fast', () => @$el.toggleClass "toggled"

        minumaximise: () =>
            @$el.toggleClass "minimised"

        startListening: () ->
            @query.on "change:constraints", @addStep "Changed Filters"
            @query.on "change:views", @addStep "Changed Columns"
            @query.on 'count:is', (count) => @states.last().trigger 'got:count', count

        initialize: (@query, @display) ->
            @currentStep = 0
            @states = new Backbone.Collection()
            @states.on 'add', (state) =>
                @$('.im-state-list').append new Step(model: state).render().el
            @states.on 'add remove', () =>
                @$('.im-trail-summary').text """query history: #{ @states.size() } states"""
                @$el.toggle @states.size() > 1

            @states.on 'revert', (state) =>
                @query = state.get('query').clone()
                num = state.get 'stepNo'
                @display.loadQuery(@query)
                @startListening()
                @states.remove  @states.filter (s) -> s.get('stepNo') > num
                state.trigger 'is:current', true

            @startListening()

        addStep: (title) -> () =>
            @states.each (state) -> state.trigger 'is:current', false
            @states.add query: @query.clone(), title: title, stepNo: @currentStep++

        render: () ->
            @$el.append """
                <div class="btn-group">
                  <a class="btn dropdown-toggle" data-toggle="dropdown" href="#">
                    <span class="im-trail-summary"></span>
                    <span class="caret"></span>
                  </a>
                  <ul class="dropdown-menu im-state-list">
                  </ul>
                </div>
                <div style="clear:both"></div>
              """
            @addStep('Original State')()
            this

