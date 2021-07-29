// TEXT BUFFER 1
// by arielm - July 16 2003
// http://www.chronotext.org

import java.util.*;

public class text_buffer_1 extends BApplet
{
  static final int w = 800;
  static final int h = 800;
  static final int margin_left = 16;
  static final int margin_top = 16;
  static final int margin_right = 16;
  static final int margin_bottom = 16;

  BImage buffer;
  XFont font;
  Text text;
  ScrollBar scrollbar;

  int scrollTop;
  int prevScrollTop = -1;

  void setup()
  {
    size(416, 400);
    noBackground();

    buffer = createBuffer(w, h, RGB, 0x00ffffff);

    FontManager fm = new FontManager(10);
    font = fm.getFont("Meta-Bold.vlw.gz", XFont.RGB_BW);
    font.setLeading(1.25f);

    text = new Text();
    text.load("tbl.txt");
    text.wordwrap(font, w - margin_left - margin_right);

    float min = 0.0f;
    float max = text.getHeight(font, text.lines.size()) + h - margin_top - margin_bottom - font.bodyHeight;
    scrollTop = 0;
    float extent = h - margin_top - margin_bottom; 
    scrollbar = new ScrollBar(width, 0.0f, 16.0f, height, ScrollBar.RIGHT, ScrollBar.TOP, ScrollBar.VERTICAL, min, max, scrollTop, extent, color(102, 102, 102), color(204, 204, 204), true);
    scrollbar.setUnitIncrement(font.bodyHeight * font.leading);
  }
  
  BImage createBuffer(int w, int h, int mode, int clear_ink)
  {
    BImage buffer = new BImage(new int[w * h], w, h, mode);
    
    if (clear_ink != 0)
    {
      for (int i = 0; i < buffer.pixels.length; i++)
      {
        buffer.pixels[i] = clear_ink;
      }
    }

    return buffer;
  }

  void loop()
  {
    scrollbar.run();

    scrollTop = (int) round(scrollbar.getValue());
    if (prevScrollTop != scrollTop)
    {
      int curLine = text.getLineFromHeight(font, scrollTop);
      int curLineTop = text.getLineTop(font, curLine);
      font.drawLines(buffer, text.data, text.lines, curLine, curLineTop - scrollTop, margin_left, margin_top, w - margin_left - margin_right, h - margin_top - margin_bottom, true);
    }
    prevScrollTop = scrollTop;

    // poor man's but fast scaling method, instead of using image(buffer, 0, 0, w / 2, h / 2)...    
    scale2Half(buffer, pixels, width);

    scrollbar.draw();
  }

  void scale2Half(BImage source, int[] dest_pixels, int dest_width)
  {
    int[] source_pixels = source.pixels;
    int source_w = source.width;
    int source_h = source.height;

    int source_start = 0;
    int dest_start = 0;

    int dest_tmp, w;
    for (int source_y = 0; source_y < source_h; source_y += 2)
    {
      dest_tmp = dest_start;
      w = source_start + source_w;
      for (; source_start < w; source_start += 2)
      {
        dest_pixels[dest_start++] = source_pixels[source_start];
      }
      dest_start = dest_tmp + dest_width;
      source_start += source_w;
    }
  }

  // ---

  class Text
  {
    StringBuffer data;
    Vector lines;

    Text()
    {
      data = new StringBuffer(256);
      lines = new Vector(100, 100);
    }

    void set(String str)
    {
      data.setLength(0);
      data.append(str);
    }

    void load(String filename)  // todo: handle exceptions
    {
      data.setLength(0);
      data.append(new String(loadBytes(filename)));
    }

    int getHeight(XFont f, int nLines)  // nLines > 0
    {
      return getLineTop(f, nLines - 1) + f.bodyHeight; 
    }

    int getLineTop(XFont f, int lineIndex)
    {
      return (int) round(lineIndex * f.bodyHeight * f.leading); 
    }

    int getLineFromHeight(XFont f, int h)
    {
      int n;
      for (n = 0; n < lines.size(); n++)
      {
        if (h < getHeight(f, n + 1))
        {
          return n;
        }
      }
      return n;  // ???
    }

    void wordwrap(XFont f, int w)
    {
      int newLineIndex = -1;
      int spaceIndex = -2;    // 2
      int wordIndex = -2;     // 3
      int hyphenIndex = -2;
      int brokenIndex = -2;
      int lastToken = 0;
      boolean newLine = true;
      int lineIndex = 0;
      int lineLength = 0;
      int x = 0;
      char last_c, next_c;
      char c = 0;
      int char_w;
      for (int i = 0; i < data.length(); i++)
      {
        last_c = c;
        c = data.charAt(i);
        next_c = i + 1 < data.length() ? data.charAt(i + 1) : 0;

        if (c == '\r' || c == '\n') // win, unix, mac
        {
          if (last_c == '\r') // win
          {
            newLineIndex = i;
            lineIndex = i + 1;
          }
          else
          {
            if (brokenIndex != i - 1)
            {
              lines.addElement(new int[] {lineIndex, lineLength});
            }
            newLineIndex = i;
            lineIndex = i + 1;
            lineLength = 0;
            x = 0;
            lastToken = 0;
            newLine = true;
          }
          continue;
        }

        if (c == ' ' && (last_c != ' ' || lineIndex == i))
        {
          spaceIndex = i;
          lastToken = 2;
        }
        else if (c != ' ' && (last_c == ' ' || lineIndex == i || hyphenIndex == i - 1))
        {
          wordIndex = i;
          lastToken = 3;
        }
        else if (wordIndex != i && c == '-' && last_c != '-' && next_c != 0 && next_c != ' ' && next_c != '\r' && next_c != '\n')
        {
          hyphenIndex = i;
        }

        char_w = f.getCharWidth(c);
        if (x + char_w >= w)
        {
          if (lastToken == 2) // lines ending with spaces
          {
            while (spaceIndex + 1 < data.length() && data.charAt(spaceIndex + 1) == ' ')  // todo: test if the boundary-check really works
            {
              spaceIndex++;
            }
            if (newLine || wordIndex >= lineIndex)
            {
              lines.addElement(new int[] {lineIndex, spaceIndex - lineIndex});
            }
            lineIndex = spaceIndex + 1;
            i = brokenIndex = lineIndex - 1;
          }
          else if (lastToken == 3 && hyphenIndex >= lineIndex && hyphenIndex < wordIndex)  // hyphen-break
          {
            lines.addElement(new int[] {lineIndex, wordIndex - lineIndex});
            lineIndex = wordIndex;
            i = lineIndex - 1;
          }
          else if (lastToken == 3 && spaceIndex >= lineIndex)  // word-break
          {
            lines.addElement(new int[] {lineIndex, wordIndex - lineIndex});
            lineIndex = wordIndex;
            i = lineIndex - 1;
          }
          else // long-line-break
          {
            lineLength += lineLength == 0 ? 1 : 0;  // for extremely narrowed-width cases...
            lines.addElement(new int[] {lineIndex, lineLength});
            lineIndex = lineIndex + lineLength;
            i = brokenIndex = lineIndex - 1;
          }

          c = data.charAt(i);
          lineLength = 0;
          x = 0;
          lastToken = 0;
          newLine = false;
        }
        else if (!newLine && x == 0 && c == ' ')  // only spaces at the beginning of a new line are enabled
        {
          lineIndex++;
        }
        else
        {
          lineLength++;
          x += char_w;
        }
      }
      if (lineLength != 0)
      {
        lines.addElement(new int[] {lineIndex, lineLength});
      }
    }
  }

  // ---

  class XFont
  {
    static final int ALPHA = 1;
    static final int RGB_BW = 2;
    static final int RGB_WB = 3;

    BFont f;
    int descent, bodyHeight;
    float leading = 1.2f; // default
    int clear_ink;

    XFont(String name, int mode)
    {
      f = loadFont(name); // todo: handle exceptions...

      bodyHeight = f.mboxY;

      int maxH = 0;
      for (int i = 0; i < f.charCount; i++)
      {
        maxH = max(maxH, bodyHeight - f.topExtent[i] + f.height[i]);
      }
      descent = maxH - bodyHeight;

      // note: we should have white instead of red here!..
      clear_ink = (mode == ALPHA || mode == RGB_WB) ? 0x00000000 : 0x00ff0000;

      for (int i = 0; i < f.charCount; i++)
      {
        int[] tmp = new int[64 * 64];
        reformat(tmp, i);

        if (mode != ALPHA)
        {
          f.images[i].format = RGB;
          for (int j = 0; j < tmp.length; j++)
          {
            int b = (mode == RGB_WB) ? tmp[j] : tmp[j] ^ 0xff;
            tmp[j] = b << 16 | b << 8 | b;
          }
        }

        f.images[i].pixels = tmp;
      }
    }

    void reformat(int[] dest_pixels, int c)
    {
      // !!! doesn't work well for all the fonts !!!

      int[] source_pixels = f.images[c].pixels;

      int w = f.width[c];
      int h = f.height[c];
      int le = f.leftExtent[c];
      int te = f.topExtent[c];

      int offset_x = max(0, le);  // part of the problem...
      int source_start = 0;
      int offset_y = bodyHeight - te;
      int dest_start = offset_y * 64 + offset_x;

      for (int iy = 0; iy < h; iy++)
      {
        for (int ix = 0; ix < w; ix++)
        {
          dest_pixels[dest_start + ix] = source_pixels[source_start + ix];
        }
        dest_start += 64;
        source_start += 64;
      }
    }

    int getCharWidth(char c)
    {
      if (c == ' ')
      {
        return getCharWidth('i');
      }

      if (!f.charExists(c))
      {
        return 0;
      }

      return f.setWidth[c - 33];
    }

    int getStringWidth(String s)
    {
      int w = 0;
      for (int i = 0; i < s.length(); i++)
      {
        w += getCharWidth(s.charAt(i));
      }
      return w;
    }

    void setLeading(float leading)
    {
      this.leading = leading;
    }

    void drawChar(BImage dest, char c, int x, int y)
    {
      drawChar(dest, c, x, y, 0, 0, getCharWidth(c), bodyHeight);
    }

    void drawChar(BImage dest, char c, int x, int y, int clip_left, int clip_top, int clip_right, int clip_bottom)
    {
      if (c == ' ')
      {
        drawRun(dest, x, y, clip_left, clip_top, clip_right, clip_bottom);
        return;
      }

      if (!f.charExists(c))
      {
        return;
      }

      int w = clip_right - clip_left;      
      int h = clip_bottom - clip_top;

      if (w <= 0 || h <= 0)
      {
        return;
      }

      int[] dest_pixels = dest.pixels;
      int dest_start = (y + clip_top) * dest.width + x + clip_left;

      int[] source_pixels = f.images[c - 33].pixels;
      int source_start = (descent + clip_top) * 64 + clip_left;

      // the following is definitely obfuscated, but fast!
      int dest_tmp, source_tmp, w1;
      for (int iy = 0; iy < h; iy++)
      {
        dest_tmp = dest_start;
        source_tmp = source_start;
        w1 = dest_start + w;
        for (; dest_start < w1; dest_start++)
        {
          dest_pixels[dest_start] = source_pixels[source_start++];
        }
        dest_start = dest_tmp + dest.width;
        source_start = source_tmp + 64;
      }
    }

    void drawRun(BImage dest, int x, int y, int clip_left, int clip_top, int clip_right, int clip_bottom)
    {
      int w = clip_right - clip_left;      
      int h = clip_bottom - clip_top;

      if (w <= 0 || h <= 0)
      {
        return;
      }

      int[] dest_pixels = dest.pixels;
      int dest_start = (y + clip_top) * dest.width + x + clip_left;
      int dest_end = dest_start + w;

      for (int iy = 0; iy < h; iy++)
      {
        for (int ix = dest_start; ix < dest_end; ix++)
        {
          dest_pixels[ix] = clear_ink;
        }
        dest_start += dest.width;
        dest_end += dest.width;
      }
    }

    void drawLine(BImage dest, StringBuffer s, int offset, int len, int x, int y, int w, int clip_top, int clip_bottom, boolean autoClear)
    {
      char c;
      int char_w;
      for (int i = 0; i < len; i++)
      {
        if (x >= w)
        {
          break;  // over the last character: exiting
        }

        c = s.charAt(offset + i);
        char_w = getCharWidth(c); 

        if (x + char_w > w)
        {
          char_w = w - x; // last character: clipping
        }

        drawChar(dest, c, x, y, 0, clip_top, char_w, clip_bottom);
        x += char_w;
      }

      if (autoClear && x < w)
      {
        drawRun(dest, x, y, 0, clip_top, w - x, clip_bottom);
      }
    }

    void drawLines(BImage dest, StringBuffer s, Vector lines, int currentLine, int yOffset, int x, int y, int w, int h, boolean autoClear)
    {
      if (w <= 0 || h <=0)
      {
        return;
      }

      int y0 = y;
      int lineH = bodyHeight;
      int clip_top, interLineH;
      int prevBottom = yOffset - (int) round(bodyHeight * leading) + bodyHeight;

      for (int i = 0; i < lines.size() - currentLine; i++)
      {
        y = yOffset + (int) round(i * bodyHeight * leading);

        if (autoClear)
        {
          interLineH = y - max(0, prevBottom);
          if (interLineH > 0)
          {
            if (prevBottom < 0)
            {
              prevBottom = 0;
              interLineH += prevBottom;
            }
            if (prevBottom + interLineH > h)
            {
              interLineH = h - prevBottom;
            }
            drawRun(dest, x, y0 + prevBottom, 0, 0, w, interLineH);
          }
        }

        if (y >= h)
        {
          break;  // over the last line: exiting
        }

        if (y + lineH > h)
        {
          lineH = h - y; // last line: clipping
        }

        clip_top = (i == 0 && yOffset < 0) ? -yOffset : 0;

        int[] coords = (int[]) lines.elementAt(currentLine + i);
        drawLine(dest, s, coords[0], coords[1], x, y0 + y, w + x, clip_top, lineH, autoClear);

        prevBottom = y + bodyHeight;
      }

      if (autoClear && prevBottom < h)
      {
        drawRun(dest, x, y0 + prevBottom, 0, 0, w, h - prevBottom);
      }
    }
  }

  // ---

  class FontManager
  {
    String[] names;
    XFont[] fonts;
    int[] modes;
    int capacity, count;

    FontManager(int capacity)
    {
      this.capacity = capacity;

      names = new String[capacity];
      fonts = new XFont[capacity];
      modes = new int[capacity];
    }

    XFont getFont(String name, int mode)
    {
      for (int i = 0; i < count; i++)
      {
        if (names[i] == name && modes[i] == mode)
        {
          return fonts[i];
        }
      }

      if (count >= capacity)
      {
        // todo: increase capacity...
      }

      XFont font = new XFont(name, mode); // todo: handle exceptions...
      names[count] = name;
      fonts[count] = font;
      modes[count] = mode;
      count++;

      return font;
    }
  }

  // ---

  class AbstractSlider extends Observable // v1.2
  {
    static final String MIN = "min";
    static final String MAX = "max";
    static final String VALUE = "value";
    static final String EXTENT = "extent";
    static final String ISADJUSTING = "isAdjusting";

    static final int HORIZONTAL = 0;
    static final int VERTICAL = 1;

    static final int LEFT = 0;
    static final int RIGHT = 1;
    static final int CENTER = 2;
    static final int TOP = 3;
    static final int BOTTOM = 4;

    float min, max, value, extent;
    float old_min, old_max, old_value, old_extent;
    boolean isAdjusting, old_isAdjusting;

    int orientation;
    float x, y, width, height;
    int color1, color2;
    int halign, valign;
    boolean enabled = true;
    boolean visible = true;

    float left, top;
    boolean enablable, degraded;
    int c1, c2;
    float[] knob_size = new float[2];
    float[] comp = new float[2];
    float[] m_comp = new float[2];
    float offset;
    boolean armed;
    boolean over, over_track, over_knob;
    boolean knob_locked;

    AbstractSlider(float min, float max, float value, float extent)
    {
      // the following contraints must be satisfied: min <= value <= value+extent <= max

      if (!(max >= min && value >= min && (value + extent) >= value && (value + extent) <= max))
      {
        throw new IllegalArgumentException(getClass() + ": invalid range properties");
      }

      this.min = old_min = min;
      this.max = old_max = max;
      this.value = old_value = value;
      this.extent = old_extent = extent;
    }

    float getMinimum()
    {
      return min;
    }

    float getMaximum()
    {
      return max;
    }

    float getValue()
    {
      return value;
    }

    float getExtent()
    {
      return extent;
    }

    boolean getValueIsAdjusting()
    {
      return isAdjusting;
    }

    boolean getEnabled()
    {
      return enabled;
    }

    boolean getVisible()
    {
      return visible;
    }

    void setMinimum(float n)
    {
      max = max(n, max);
      value = max(n, value);
      extent = min(max - value, extent);
      min = n;
      updateRangeProperties();
    }

    void setMaximum(float n)
    {
      min = min(n, min);
      extent = min(n - min, extent);
      value = min(n - extent, value);
      max = n;
      updateRangeProperties();
    }

    void setValue(float n)
    {
      value = constrain(n, min, max - extent);
      updateRangeProperties();
    }

    void setExtent(float n)
    {
      extent = constrain(n, 0.0f, max - value);
      updateRangeProperties();
    }

    void setValueIsAdjusting(boolean b)
    {
      isAdjusting = b;

      if (isAdjusting != old_isAdjusting)
      {
        old_isAdjusting = isAdjusting;
        fireNotification(ISADJUSTING);
      }
    }

    void setColors(int color1, int color2)
    {
      this.color1 = color1;
      this.color2 = color2;
    }

    void setLocation(float x, float y)
    {
      setBounds(x, y, width, height);
    }

    void setSize(float width, float height)
    {
      setBounds(x, y, width, height);
    }

    void setBounds(float x, float y, float width, float height)
    {
      this.left = x - (halign == LEFT ? 0.0f : (halign == RIGHT ? width : width / 2.0f));
      this.top = y - (valign == TOP ? 0.0f : (valign == BOTTOM ? height : height / 2.0f));
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;

      recalc();
    }

    void setEnabled(boolean b)
    {
      enabled = b;
    }

    void setVisible(boolean b)
    {
      visible = b;
    }

    void updateRangeProperties()
    {
      enablable = getIsEnablable();
      rangePropertyChanged();
      updateComp();
      updateExtent();
    }

    boolean getIsEnablable() // always overriden...
    {
      return true;
    }

    void updateComp()
    {
    }

    void updateExtent()
    {
    }

    void recalc()
    {
    }

    void rangePropertyChanged()
    {
      if (min != old_min)
      {
        old_min = min;
        fireNotification(MIN);
      }

      if (max != old_max)
      {
        old_max = max;
        fireNotification(MAX);
      }

      if (value != old_value)
      {
        old_value = value;
        fireNotification(VALUE);
      }

      if (extent != old_extent)
      {
        old_extent = extent;
        fireNotification(EXTENT);
      }
    }

    void fireNotification(String propertyName)
    {
      setChanged();
      notifyObservers(propertyName);
    }
  }

  class ScrollBar extends AbstractSlider  // v1.2
  {
    boolean hasButtons;

    float unitIncrement = 1.0f;
    float blockIncrement;
    boolean dirtyBI;
    float[] track_pos = new float[2], track_size = new float[2];
    float[] button_plus_pos = new float[2], button_size = new float[2];
    float direction;
    boolean over_button_minus, over_button_plus;
    boolean track_locked, button_minus_locked, button_plus_locked;

    final float[][] arrow =
    {
      {1.5f, 3.0f, 3.0f, 2.0f, 1.5f, 1.5f},
      {3.0f, 3.0f, 1.5f, 2.0f, 3.0f, 1.5f},
      {3.0f, 1.5f, 2.0f, 3.0f, 1.5f, 1.5f},
      {3.0f, 3.0f, 2.0f, 1.5f, 1.5f, 3.0f}
    };

    ScrollBar(float x, float y, float width, float height, int halign, int valign, int orientation, float min, float max, float value, float extent, int color1, int color2, boolean hasButtons)
    {
      super(min, max, value, extent);

      this.halign = halign;
      this.valign = valign;
      this.orientation = orientation;
      this.color1 = color1;
      this.color2 = color2;
      this.hasButtons = hasButtons;

      c1 = orientation;
      c2 = 1 - c1;

      enablable = getIsEnablable();
      setBounds(x, y, width, height);
    }

    void setUnitIncrement(float unitIncrement)
    {
      this.unitIncrement = unitIncrement;
    }

    void setBlockIncrement(float blockIncrement)
    {
      this.blockIncrement = blockIncrement;
      dirtyBI = true;
    }

    void run()
    {
      button_minus_locked = visible && enablable && enabled && hasButtons && button_minus_locked && mousePressed;
      button_plus_locked = visible && enablable && enabled && hasButtons && button_plus_locked && mousePressed;
      track_locked = visible && enablable && enabled && track_locked && mousePressed;
      knob_locked = visible && enablable && enabled && knob_locked && mousePressed;

      setValueIsAdjusting(button_minus_locked || button_plus_locked || track_locked || knob_locked);

      m_comp[0] = mouseX;
      m_comp[1] = mouseY;

      over = !degraded && visible && enablable && enabled && !armed && !button_minus_locked && !button_plus_locked && !track_locked && !knob_locked && mousePressed && (m_comp[0] >= left && m_comp[0] < (left + width) && m_comp[1] >= top && m_comp[1] < (top + height));
      armed = !over && mousePressed;

      if (degraded || !visible || !enablable || !enabled)
      {
        return;
      }

      over_button_minus = hasButtons && over && (m_comp[0] >= left && m_comp[0] < (left + button_size[0]) && m_comp[1] >= top && m_comp[1] < (top + button_size[1]));
      over_button_plus = hasButtons && over && !over_button_minus && (m_comp[c1] >= button_plus_pos[c1] && m_comp[c1] < (button_plus_pos[c1] + button_size[c1]) && m_comp[c2] >= button_plus_pos[c2] && m_comp[c2] < (button_plus_pos[c2] + button_size[c2]));

      over_track = over && !over_button_minus && !over_button_plus && (m_comp[c1] >= track_pos[c1] && m_comp[c1] < (track_pos[c1] + track_size[c1]) && m_comp[c2] >= track_pos[c2] && m_comp[c2] < (track_pos[c2] + track_size[c2]));

      over_knob = over_track && (m_comp[c1] >= (track_pos[c1] + comp[c1]) && m_comp[c1] < (track_pos[c1] + comp[c1] + knob_size[c1]) && m_comp[c2] >= top && (m_comp[c2] + comp[c2]) < (track_pos[c2] + comp[c2] + knob_size[c2]));

      if (over_button_minus)
      {
        button_minus_locked = true;
        setValueIsAdjusting(true);
        direction = -1.0f;
      }
      else if (over_button_plus)
      {
        button_plus_locked = true;
        setValueIsAdjusting(true);
        direction = 1.0f;
      }
      else if (over_knob)
      {
        knob_locked = true;
        setValueIsAdjusting(true);
        offset = (m_comp[c1] - track_pos[c1] - comp[c1]) * (max - min) / track_size[c1];
      }
      else if (over_track)
      {
        track_locked = true;
        setValueIsAdjusting(true);
        direction = (m_comp[c1] - track_pos[c1] > comp[c1]) ? 1.0f : -1.0f;
      }

      if (button_minus_locked || button_plus_locked)
      {
        setValue(value + unitIncrement * direction);
      }
      else if (track_locked)
      {
        if ((direction < 0.0 && m_comp[c1] - track_pos[c1] < comp[c1]) || (direction > 0.0 && m_comp[c1] - track_pos[c1] - knob_size[c1] > comp[c1]))
        {
          setValue(value + blockIncrement * direction);
        }
      }
      else if (knob_locked)
      {
        setValue((m_comp[c1] - track_pos[c1]) * (max - min) / track_size[c1] - offset);
      }
    }

    boolean getIsEnablable()
    {
      return !(extent == 0.0 || extent == max);
    }

    void updateComp()
    {
      if (!degraded)
      {
        comp[c1] = !enablable ? 0.0f : (value - min) / (max - min) * track_size[c1];
      }
    }

    void updateExtent()
    {
      if (!degraded)
      {
        knob_size[c1] = !enablable ? 0.0f : extent * track_size[c1] / (max - min);

        if (!dirtyBI)
        {
          blockIncrement = extent;
        }
      }
    }

    void recalc()
    {
      final float gap = 1.0f;

      if (hasButtons)
      {
        button_size[c1] = orientation == HORIZONTAL ? height : width;
        button_size[c2] = button_size[c1];
        button_plus_pos[c1] = (orientation == HORIZONTAL ? (left + width) : (top + height)) - button_size[c1];
        button_plus_pos[c2] = (orientation == HORIZONTAL ? top : left);
      }

      track_size[c1] = (orientation == HORIZONTAL ? width : height) - (hasButtons ? (2.0f * (button_size[c1] + gap)) : 0.0f);
      track_size[c2] = orientation == HORIZONTAL ? height : width;
      track_pos[c1] = (orientation == HORIZONTAL ? left : top) + (hasButtons ? (button_size[c1] + gap) : 0.0f);
      track_pos[c2] = orientation == HORIZONTAL ? top : left;

      degraded = track_size[c1] < 1.0; // gracefull degradation at paranormal sizes
      if (degraded)
      {
        if (hasButtons && track_size[c1] < -2.0 * gap)
        {
          button_size[c1] = (orientation == HORIZONTAL ? width : height) / 2.0f;
          button_plus_pos[c1] = (orientation == HORIZONTAL ? (left + width) : (top + height)) - button_size[c1];
        }
      }

      updateExtent();
      knob_size[c2] = track_size[c2];

      updateComp();
      comp[c2] = 0.0f;
    }

    void draw()
    {
      if (visible)
      {
        if (hasButtons)
        {
          drawButton(left, top, (orientation == HORIZONTAL ? 0 : 2) + 0, button_minus_locked);
          drawButton(button_plus_pos[0], button_plus_pos[1], (orientation == HORIZONTAL ? 0 : 2) + 1, button_plus_locked);
        }

        if (!degraded)
        {
          drawTrack();

          if (enablable && enabled)
          {
            drawKnob();
          }
        }
      }
    }

    void drawButton(float l, float t, int dir, boolean isLocked)
    {
      stroke(color1);
      fill(isLocked ? color1 : color2);
      rectMode(CORNER);
      rect(l, t, button_size[0] - 1.0f, button_size[1] - 1.0f);

      stroke(isLocked ? color2 : color1);
      beginShape(LINE_STRIP);
      vertex(l + button_size[0] / arrow[dir][0], t + button_size[1] / arrow[dir][1]);
      vertex(l + button_size[0] / arrow[dir][2], t + button_size[1] / arrow[dir][3]);
      vertex(l + button_size[0] / arrow[dir][4], t + button_size[1] / arrow[dir][5]);
      endShape();
    }

    void drawTrack()
    {
      noStroke();
      fill(track_locked ? (direction > 0.0 ? color1 : color2) : color2);
      rectMode(CORNER);
      rect(track_pos[0], track_pos[1], track_size[0], track_size[1]);

      if (track_locked)
      {
        fill(direction > 0.0 ? color2 : color1);
        if (orientation == HORIZONTAL)
        {
          rect(track_pos[0], track_pos[1], comp[0], track_size[1]);
        }
        else
        {
          rect(track_pos[0], track_pos[1], track_size[0], comp[1]);
        }
      }
    }

    void drawKnob()
    {
      stroke(color1);
      fill(knob_locked ? color1 : color2);
      rectMode(CORNER);
      rect(track_pos[0] + comp[0], track_pos[1] + comp[1], knob_size[0] - 1.0f, knob_size[1] - 1.0f);
    }
  }
}
