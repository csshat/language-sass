# Deps

{css, utils} = require 'octopus-helpers'
{_} = utils


# Private fns

_declaration = ($$, scssSyntax, property, value, modifier) ->
  return if not value? or value == ''

  if scssSyntax
    semicolon = ';'
  else
    semicolon = ''

  if modifier
    value = modifier(value)

  $$ "#{property}: #{value}#{semicolon}"


_mixin = ($$, scssSyntax, name, value, modifier) ->
  return unless value?

  if scssSyntax
    include = '@include '
    semicolon = ';'
  else
    include = '+'
    semicolon = ''

  if modifier
    value = modifier(value)

  $$ "#{include}#{name}(#{value})#{semicolon}"


renderColor = (color, colorVariable) ->
  colorVariable = renderVariable(colorVariable)
  if color.a < 1
    "rgba(#{colorVariable}, #{color.a})"
  else
    colorVariable


_comment = ($, showComments, text) ->
  return unless showComments
  $ "// #{text}"


defineVariable = (name, value, options) ->
  semicolon = if options.scssSyntax then ';' else ''
  "$#{name}: #{value}#{semicolon}"


renderVariable = (name) -> "$#{name}"


_convertColor = _.partial(css.convertColor, renderColor)


_startSelector = ($, selector, scssSyntax, selectorOptions, text) ->
  return unless selector
  curlyBracket = if scssSyntax then ' {' else ''
  $ '%s%s', utils.prettySelectors(text, selectorOptions), curlyBracket


_endSelector = ($, scssSyntax, selector) ->
  $ '}' if selector and scssSyntax


setNumberValue = (number) ->
  converted = parseInt(number, 10)
  if not number.match(/^\d+(\.\d+)?$/)
    return 'Please enter numeric value'
  else
    return converted


class Sass

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $$, @options.scssSyntax)
    mixin = _.partial(_mixin, $$, @options.scssSyntax)
    comment = _.partial(_comment, $, @options)

    rootValue = switch @options.unit
      when 'px' then 0
      when 'em' then @options.emValue
      when 'rem' then @options.remValue
    unit = _.partial(css.unit, @options.unit, rootValue)

    convertColor = _.partial(_convertColor, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, @options.quoteType)

    selectorOptions =
      separator: @options.selectorTextStyle
      selector: @options.selectorType
      maxWords: 3
      fallbackSelectorPrefix: 'layer'
    startSelector = _.partial(_startSelector, $, @options.selector, @options.scssSyntax, selectorOptions)
    endSelector = _.partial(_endSelector, $, @options.scssSyntax, @options.selector)

    if @type == 'textLayer'
      for textStyle in css.prepareTextStyles(@options.inheritFontStyles, @baseTextStyle, @textStyles)

        if @options.showComments
          comment(css.textSnippet(@text, textStyle))

        if @options.selector
          if textStyle.ranges
            selectorText = utils.textFromRange(@text, textStyle.ranges[0])
          else
            selectorText = @name

          startSelector(selectorText)

        if not @options.inheritFontStyles or textStyle.base
          if @options.showAbsolutePositions
            if @options.mixinLibrary is 'Bourbon'
              mixin('position', "absolute, #{unit(@bounds.top)} null null #{unit(@bounds.left)}")
            else
              declaration('position', 'absolute')
              declaration('left', @bounds.left, unit)
              declaration('top', @bounds.top, unit)

          if @bounds
            if @options.mixinLibrary is 'Bourbon'
              if @bounds.width == @bounds.height
                mixin('size', @bounds.width, unit)
              else
                mixin('size', "#{unit(@bounds.width)}, #{unit(@bounds.height)}")
            else
              declaration('width', @bounds.width, unit)
              declaration('height', @bounds.height, unit)

          mixin('opacity', @opacity)

          if @shadows
            declaration('text-shadow', css.convertTextShadows(convertColor, unit, @shadows))

        fontStyles(textStyle)

        endSelector()
        $.newline()
    else
      if @options.showComments
        comment("Style for \"#{utils.trim(@name)}\"")

      startSelector(@name)

      if @options.showAbsolutePositions
        if @options.mixinLibrary is 'Bourbon'
          mixin('position', "absolute, #{unit(@bounds.top)} null null #{unit(@bounds.left)}")
        else
          declaration('position', 'absolute')
          declaration('left', @bounds.left, unit)
          declaration('top', @bounds.top, unit)

      if @bounds
        if @options.mixinLibrary is 'Bourbon'
          if @bounds.width == @bounds.height
            mixin('size', @bounds.width, unit)
          else
            mixin('size', "#{unit(@bounds.width)}, #{unit(@bounds.height)}")
        else
          declaration('width', @bounds.width, unit)
          declaration('height', @bounds.height, unit)

      if @options.mixinLibrary is 'Compass'
        mixin('opacity', @opacity)
      else
        declaration('opacity', @opacity)

      if @background
        declaration('background-color', @background.color, convertColor)

        if @background.gradient
          gradientStr = css.convertGradients(convertColor, {gradient: @background.gradient, @bounds})

          if gradientStr
            if @options.mixinLibrary is 'none'
              declaration('background-image', gradientStr)
            else
              mixin('background-image', gradientStr)

      if @borders
        border = @borders[0]
        declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

      if @options.mixinLibrary is 'Compass'
        mixin('border-radius', @radius, css.radius)
      else
        declaration('border-radius', @radius, css.radius)

      if @shadows
        if @options.mixinLibrary is 'Compass'
          mixin('box-shadow', css.convertShadows(convertColor, unit, @shadows))
        else
          declaration('box-shadow', css.convertShadows(convertColor, unit, @shadows))

      endSelector()


module.exports = {defineVariable, renderVariable, setNumberValue, renderClass: Sass}