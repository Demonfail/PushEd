/// PEd_guiDrawInput(x, y, width, value, [disabled, [defaultValue]])
/**
 * @brief Draws an input at the given position.
 * @param {real}        x            The x position to draw the input at.
 * @param {real}        y            The y position to draw the input at.
 * @param {real}        width        The width of the input.
 * @param {real/string} value        The value in the input.
 * @param {bool}        [disabled]   True to disable editing the input value.
 * @param {real/string} defaultValue The value to draw when the value is an empty string.
 * @return {real/string/undefined} The new input value when done editing or undefined while
 *                                 editing.
 */
var _padding = ceil(guiFontWidth * 0.5) + 1;
var _id = PEd_guiEncodeID(guiShapeFilling, guiShapeId++);
var _delegate = guiShapeFilling;
var _x = argument[0];
var _xStart = _x;
var _y = argument[1];
var _yStart = _y;
var _width = argument[2];
var _active = (guiInputActive == _id);

var _value;
if (guiInputActive == _id)
{
    _value = guiInputString;
}
else
{
    _value = string(argument[3]);
}
var _type = is_real(argument[3]);
var _stringLength = string_length(_value);
var _mouseOver = (PEd_guiShapeIsHovered(_delegate)
                  && guiMouseX > _x
                  && guiMouseY > _y
                  && guiMouseX < _x + _width
                  && guiMouseY < _y + guiInputSpriteHeight);
var _maxCharCount = floor((_width - _padding * 2 ) / guiFontWidth);

var _disabled = false;
if (argument_count > 4)
{
    _disabled = argument[4];
}

////////////////////////////////////////////////////////////////////////////////
//
// Draw input
//

// Background
draw_sprite_ext(guiInputSprite, 0, _x, _y, 1, 1, 0, PEdColour.Input, 1);
draw_sprite_stretched_ext(guiInputSprite, 1, _x + guiInputSpriteWidth, _y,
                      _width - guiInputSpriteWidth * 2, guiInputSpriteHeight, PEdColour.Input, 1);
draw_sprite_ext(guiInputSprite, 2, _x + _width - guiInputSpriteWidth, _y, 1, 1, 0, PEdColour.Input, 1);

// Text
var _textX = _x + _padding;
var _textY = _y + round((guiInputSpriteHeight - guiFontHeight) * 0.5);
var _maxCharCount = floor((_width - _padding * 2) / guiFontWidth);
var _colSelection = PEdColour.Active;

if (_mouseOver)
{
    guiCursor = cr_beam;
}

if (_active)
{
    if (guiInputIndex[1] - guiInputDrawIndexStart > _maxCharCount)
    {
        guiInputDrawIndexStart += guiInputIndex[1] - guiInputDrawIndexStart - _maxCharCount;
    }
    else if (guiInputDrawIndexStart > guiInputIndex[1])
    {
        guiInputDrawIndexStart -= guiInputDrawIndexStart - guiInputIndex[1];
    }

    _value = string_copy(_value, guiInputDrawIndexStart, _maxCharCount);

    if (guiInputIndex[0] == guiInputIndex[1])
    {
        // Beam
        var _beamX = _textX + guiFontWidth * (guiInputIndex[0] - guiInputDrawIndexStart);
        draw_text(_textX, _textY, _value);
        PEd_guiDrawRectangle(_beamX, _textY, 1, guiFontHeight, _colSelection);
    }
    else
    {
        // Selection
        //var _stringLength = string_length(_value);
        var _minIndex = clamp(min(guiInputIndex[0], guiInputIndex[1]) - guiInputDrawIndexStart, 0, _stringLength);
        var _maxIndex = clamp(max(guiInputIndex[0], guiInputIndex[1]) - guiInputDrawIndexStart, 0, _stringLength);
        var _rectMinX = _textX + guiFontWidth * _minIndex;
        var _rectMaxX = _textX + guiFontWidth * _maxIndex;
        
        draw_text(_textX, _textY, string_copy(_value, 1, _minIndex));                                   // Text before selection
        PEd_guiDrawRectangle(_rectMinX, _textY, _rectMaxX - _rectMinX, guiFontHeight, _colSelection);   // Selection rectangle
        draw_text_colour(_rectMinX, _textY, string_copy(_value, _minIndex + 1, _maxIndex - _minIndex),  // Selected text
                         PEdColour.TextSelected, PEdColour.TextSelected, PEdColour.TextSelected, PEdColour.TextSelected, 1);
        draw_text(_rectMaxX, _textY, string_delete(_value, 1, _maxIndex));                              // Text after selection
    }
}
else
{
    var _drawValue = _value;
    if (argument_count > 5
        && _value == "")
    {
        _drawValue = argument[5];
    }
    PEd_guiDrawTextPart(_textX, _textY, _drawValue, _maxCharCount * guiFontWidth);
}

////////////////////////////////////////////////////////////////////////////////
//
// Input logic
//
if (mouse_check_button_pressed(mb_left)
    || mouse_check_button_pressed(mb_right)) 
{
    // Select input
    if (_mouseOver
        && !_disabled)
    {
        if (guiInputActive == noone) 
        {
            guiInputActive = _id;
            guiInputString = _value;
            guiInputDrawIndexStart = 1;
            guiInputIndex[0] = 1;
            guiInputIndex[1] = 1;
            keyboard_string = "";
        }
    }
    else if (_active
        && (!PEd_guiShapeExists(guiContextMenu)
        || (guiContextMenu != noone
        && !PEd_guiShapeDelegatesRecursive(guiContextMenu, guiShapeHovered)))) 
    {
        // Return value when clicked outside of the input
        guiInputActive = noone;
        if (PEd_guiShapeExists(_delegate))
        {
            PEd_guiRequestRedraw(_delegate);
        }
        if (_type)
        {
            return real(_value);
        }
        return _value;
    }
}

if (_active) 
{
    // Select text
    if (mouse_check_button(mb_left)
        && _mouseOver) 
    {
        var _index = clamp(round((guiMouseX - _xStart - _padding) / guiFontWidth) + guiInputDrawIndexStart, 1, _stringLength + 1);
        if (mouse_check_button_pressed(mb_left))
        {
            guiInputIndex[0] = _index;
        }
        guiInputIndex[1] = _index;
    }
    else if (mouse_check_button_pressed(mb_right)
        && _mouseOver)
    {
        // Open context menu
        var _contextMenu = PEd_guiCreateContextMenu();
        PEd_guiMenuInput(_contextMenu);
        PEd_guiShowContextMenu(_contextMenu);
        
        // TODO: Select word in input on double click
        /*var _index = clamp(round((guiMouseX - _xStart - _padding) / guiFontWidth) + guiInputDrawIndexStart, 1, _stringLength + 1);
        var i, _char;
        _char = string_char_at(_value, _index);
        if (_char != " ")
        {
            for (i = _index; i > 1; i--) 
            {
                _char = string_char_at(_value, i);
                if (_char == " ")
                {
                    i++;
                    break;
                }
            }
            guiInputIndex[0] = i;
            
            for (i = _index; i < _stringLength + 1; i++) 
            {
                _char = string_char_at(_value, i);
                if (_char == " ")
                    break;
            }
            guiInputIndex[1] = i;
        }*/
    }
        
    // Return value when enter is pressed
    if (keyboard_check_pressed(vk_enter)) 
    {
        guiInputActive = noone;
        if (PEd_guiShapeExists(_delegate))
        {
            PEd_guiRequestRedraw(_delegate);
        }
        if (_type)
        {
            return real(_value);
        }
        return _value;
    }
}

return undefined;
