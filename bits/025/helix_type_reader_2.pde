// HELIX TYPE READER 2
// by arielm - May 26, 2003
// http://www.chronotext.org

// Original text by Soren Kierkegaard ("The Rotation Method" in "Either / Or"...)
// http://www.newcriterion.com/articles.cfm/What-did-Kierkegaard-want---2132
// http://www.zip.com.au/~jtranter/jacket04/lehman-postmod.html

float fps;
float fovy, aspect;
float elevation, azimuth, distance;

BFont f;
Helix[] helices;
ScrollBar[] scrollbars;

void setup()
{
  fps = 20.0;

  size(300, 300);
  background(255);
  framerate(fps);
  hint(SMOOTH_IMAGES);

  // ---

  fovy = 60.0;
  aspect = (float)width / (float)height;

  distance = 170.0;
  elevation = radians(275.0);
  azimuth = radians(45.0);

  // ---

  f = loadFont("Meta-Bold.vlw.gz");  // don't forget to have this font included in your "data" folder...

  String[] lines =
  {
    "The whole secret lies in arbitrariness. People usually think it is easy to be arbitrary, but it requires much study to succeed in being arbitrary so as not to lose oneself in it, but so as to derive satisfaction from it. One does not enjoy the immediate but something quite different which he arbitrarily imports into it. You go to see the middle of a play, you read the third part of a book. . . . By this means you insure yourself a very different kind of enjoyment from that which the author has been so kind as to plan for you. You enjoy something entirely accidental; you consider the whole of existence from this standpoint; let its reality be stranded thereon. . . . You transform something accidental into the absolute.",
    "Surely no one will prove himself so great a bore as to contradict me in this. . . . The gods were bored, and so they created man. Adam was bored because he was alone, and so Eve was created. Thus boredom entered the world, and increased in proportion to the increase of population. Adam was bored alone; then Adam and Eve were bored together; then Adam and Eve and Cain and Abel were bored en famille; then the population of the world increased, and the peoples were bored en masse. To divert themselves they conceived the idea of constructing a tower high enough to reach the heavens. This idea is itself as boring as the tower was high, and constitutes a terrible proof of how boredom gained the upper hand. "
  };

  color[][] colors =
  {
    {color(102, 102, 102), color(204, 051, 000)},
    {color(102, 102, 102), color(204, 051, 000)},
    {color(224, 224, 224), color(255, 224, 204)}
  };

  Text[] txt =
  {
    new Text(lines[0], f, colors[0][0], 10.0),
    new Text(lines[1], f, colors[0][1], 10.0)
  };

  buildTower(0.0, 0.0, -32.0, 3.0, 80.0, 40.0, 96.0, txt, colors);
}

void buildTower(float x, float y, float z, float turns, float r1, float r2, float h, Text[] txt, color[][] colors)
{
  float t = 5.0;  // time to slide (in seconds)...
  helices = new Helix[2];
  scrollbars = new ScrollBar[helices.length];

  float o = 0.0;
  float a;
  for (int i = 0; i < helices.length; i++)
  {
    helices[i] = new Helix(x, y, z, turns, r1, r2, h, txt[i]);
    helices[i].setOffset(Helix.END);
    helices[i].setSlidingSpeed(0.0);
    a = 2.0 * (txt[i].getWidth() + helices[i].getLength()) / (t  * fps * t * fps);
    helices[i].setSlidingAcceleration(-a);
    helices[i].startSliding();

    scrollbars[i] = new ScrollBar(8.0, 292.0 + o, 284.0, 13.0, ScrollBar.LEFT, ScrollBar.BOTTOM, ScrollBar.HORIZONTAL, 0.0, 2.0 * helices[i].getLength() + txt[i].getWidth(), 0.0, helices[i].getLength(), colors[1][i], colors[2][i], true);
    scrollbars[i].setUnitIncrement(4.0 * 10.0 / fps);  // while a scrollbar button is pressed, the text is scrolling at (4 * fontSize) pixels per second...

    z += 8.0;
    o += - 13.0 - 2.0;
  }
}

void loop()
{
  for (int i = 0; i < scrollbars.length; i++)  // keep it at the beginning...
  {
    scrollbars[i].run();
  }

  beginCamera();
  perspective(fovy, aspect, 1.0, 1000.0);
  translate(0.0, 0.0, -distance);
  rotateX(-elevation);
  rotateZ(-azimuth);
  endCamera();

  for (int i = 0; i < helices.length; i++)
  {
    if (!helices[i].sliding)
    {
      helices[i].offset = -scrollbars[i].getValue() + helices[i].getLength();
    }

    helices[i].run();

    if (helices[i].sliding)
    {
      scrollbars[i].setValue(helices[i].getLength() - helices[i].offset);
    }
  }

  for (int i = 0; i < scrollbars.length; i++)  // keep it at the end...
  {
    scrollbars[i].draw();
  }
}

// ---

class Helix
{
  static final byte BEGINNING = 0;
  static final byte END = 1;

  float x, y, z, turns, r1, r2, h;

  Text txt;
  float offset;

  float d, D, r, l, L, dz, dr;
  boolean conical;
  int index;
  char ch;
  float w;
  float rouge, vert, bleu;

  boolean sliding, foo;
  float offset_v, offset_a;
  
  Helix(float x, float y, float z, float turns, float r1, float r2, float h, Text txt)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.turns = turns;
    this.r1 = r1;
    this.r2 = r2;
    this.h = h;

    this.txt = txt;
  }

  void run()
  {
    if (foo)
    {
      sliding = false;
    }

    if (sliding)
    {
      offset += offset_v;
      offset_v += offset_a;

      if (offset < -txt.getWidth())
      {
        offset = -txt.getWidth();
        stopSliding(true);
      }
      else if (offset > getLength())
      {
        offset = getLength();
        stopSliding(true);
      }
    }

    draw();
  }

  void draw()
  {
    D = offset;

    l = TWO_PI * turns;
    L = PI * turns * (r1 + r2);
    dz = h / l;

    conical = (abs(r1 - r2) > 0.5);  // avoids infinity and divisions by zero with cylindrical helices (r1 = r2)
    if (conical)
    {
      dr = (r2 - r1) / l;
    }
    else
    {
      r = r1;
    }

    index = txt.line.length();
    char ch;

    txt.font.setSize(txt.sz);

    colorMode(RGB, 255, 255, 255, 1);
    rouge = red(txt.col);
    vert = green(txt.col);
    bleu = blue(txt.col);

    while(index > 0)
    {
      ch = txt.line.charAt(--index);
      w = txt.font.charWidth(ch);
      D += w;

      if (D + w > L)
      {
        break;
      }

      if (D >= w)
      {
        if (conical)
        {
          r = sqrt(r1 * r1 + 2.0 * dr * D);
          d = (r - r1) / dr;
        }
        else
        {
          d = D / r;
        }

        fill(rouge, vert, bleu, 0.6 + 0.4 * cos(-azimuth + d));  // simple depth effect...

        push();
        translate(x - sin(d) * r, y + cos(d) * r, z + d * dz);
        rotateX(-HALF_PI);
        rotateY(-d);
        rotateZ(atan2(h , l * r));  // banking...
        txt.font.drawChar(ch, 0.0, 0.0);
        pop();
      }
    }
  }

  void setOffset(byte flag)
  {
    offset = (flag == BEGINNING) ? -txt.getWidth() : getLength();
  }

  void setOffset(float newOffset)
  {
    offset = newOffset;
  }

  float getLength()
  {
    return PI * turns * (r1 + r2);
  }

  void setSlidingSpeed(float v)
  {
    offset_v = v;
  }

  void setSlidingAcceleration(float a)
  {
    offset_a = a;
  }

  void startSliding()
  {
    sliding = true;
  }

  void stopSliding()
  {
    sliding = false;
  }

  void stopSliding(boolean delayed)
  {
    foo = true;
  }
}

// ---

class Text
{
  StringBuffer line;
  BFont font;
  color col;
  float sz;

  float w;
  boolean w_dirty = true;

  Text(String line, BFont font, color col, float sz)
  {
    this.line = new StringBuffer(line);
    this.font = font;
    this.col = col;
    this.sz = sz;
  }

  float getWidth()
  {
    if (w_dirty)
    {
      w = 0.0;
      float l = line.length();

      font.setSize(sz);
      for (int i = 0; i < l; i++)
      {
        w += font.charWidth(line.charAt(i));
      }
      w_dirty = false;
    }

    return w;
  }
}

// ---

class AbstractSlider extends Observable
{
  static final int HORIZONTAL = 0;
  static final int VERTICAL = 1;

  static final int LEFT = 0;
  static final int RIGHT = 1;
  static final int CENTER = 2;
  static final int TOP = 3;
  static final int BOTTOM = 4;

  float min, max, value, extent;
  float old_min, old_max, old_value, old_extent;

  int orientation;
  float x, y, width, height;
  color color1, color2;
  int halign, valign;
  boolean enabled = true;

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
    extent = constrain(n, 0.0, max - value);
    updateRangeProperties();
  }

  void setColors(color color1, color color2)
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
    this.left = x - (halign == LEFT ? 0.0 : (halign == RIGHT ? width : width / 2.0));;
    this.top = y - (valign == TOP ? 0.0 : (valign == BOTTOM ? height : height / 2.0));
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;

    recalc();
  }

  boolean getEnabled()
  {
    return enabled;
  }

  void setEnabled(boolean b)
  {
    enabled = b;
  }

  void updateRangeProperties()
  {
    enablable = getIsEnablable();
    rangePropertiesChanged();
    updateComp();
    updateExtent();
  }

  boolean getIsEnablable()  // always overriden...
  {
    return true;
  }

  void updateComp() {}

  void updateExtent() {}

  void recalc() {}

  void rangePropertiesChanged()
  {
    // this is the place to implement an event-posting system...
  }
}

class ScrollBar extends AbstractSlider
{
  boolean hasButtons;

  float unitIncrement = 1.0;
  float blockIncrement;
  boolean dirtyBI;
  float[] track_pos = new float[2], track_size = new float[2];
  float[] button_plus_pos = new float[2], button_size = new float[2];
  float direction;
  boolean over_button_minus, over_button_plus;
  boolean track_locked, button_minus_locked, button_plus_locked;

  ScrollBar(float x, float y, float width, float height, int halign, int valign, int orientation, float min, float max, float value, float extent, color color1, color color2, boolean hasButtons)
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
    button_minus_locked = enablable && enabled && hasButtons && button_minus_locked && mousePressed;
    button_plus_locked = enablable && enabled && hasButtons && button_plus_locked && mousePressed;
    track_locked = enablable && enabled && track_locked && mousePressed;
    knob_locked = enablable && enabled && knob_locked && mousePressed;

    m_comp[0] = mouseX;
    m_comp[1] = mouseY;

    over = !degraded && enablable && enabled && !armed && !button_minus_locked && !button_plus_locked && !track_locked && !knob_locked && mousePressed && (m_comp[0] >= left && m_comp[0] < (left + width) && m_comp[1] >= top && m_comp[1] < (top + height));
    armed = !over && mousePressed;

    if (degraded)
    {
      return;
    }

    over_button_minus = hasButtons && over && (m_comp[0] >= left && m_comp[0] < (left + button_size[0]) && m_comp[1] >= top && m_comp[1] < (top + button_size[1]));
    over_button_plus = hasButtons &&over && !over_button_minus && (m_comp[c1] >= button_plus_pos[c1] && m_comp[c1] < (button_plus_pos[c1] + button_size[c1]) && m_comp[c2] >= button_plus_pos[c2] && m_comp[c2] < (button_plus_pos[c2] + button_size[c2]));

    over_track = over && !over_button_minus && !over_button_plus && (m_comp[c1] >= track_pos[c1] && m_comp[c1] < (track_pos[c1] + track_size[c1]) && m_comp[c2] >= track_pos[c2] && m_comp[c2] < (track_pos[c2] + track_size[c2]));

    over_knob = over_track && (m_comp[c1] >= (track_pos[c1] + comp[c1]) && m_comp[c1] < (track_pos[c1] + comp[c1] + knob_size[c1]) && m_comp[c2] >= top && (m_comp[c2] + comp[c2]) < (track_pos[c2] + comp[c2] + knob_size[c2]));

    if (over_button_minus)
    {
      button_minus_locked = true;
      direction = -1.0;
    }
    else if (over_button_plus)
    {
      button_plus_locked = true;
      direction = 1.0;
    }
    else if (over_knob)
    {
      knob_locked = true;
      offset = (m_comp[c1] - track_pos[c1] - comp[c1]) * (max - min) / track_size[c1];
    }
    else if (over_track)
    {
      track_locked = true;
      direction = (m_comp[c1] - track_pos[c1] > comp[c1]) ? 1.0 : -1.0;
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
      comp[c1] = !enablable ? 0.0 : (value - min) / (max - min) * track_size[c1];
    }
  }

  void updateExtent()
  {
    if (!degraded)
    {
      knob_size[c1] = !enablable ? 0.0 : extent * track_size[c1] / (max - min);

      if (!dirtyBI)
      {
        blockIncrement = extent;
      }
    }
  }

  void recalc()
  {
    static final float gap = 1.0;

    if (hasButtons)
    {
      button_size[c1] = orientation == HORIZONTAL ? height : width;
      button_size[c2] = button_size[c1];
      button_plus_pos[c1] = (orientation == HORIZONTAL ? (left + width) : (top + height)) - button_size[c1];
      button_plus_pos[c2] = (orientation == HORIZONTAL ? top : left);
    }

    track_size[c1] = (orientation == HORIZONTAL ? width : height) - (hasButtons ? (2.0 * (button_size[c1] + gap)) : 0.0);
    track_size[c2] = orientation == HORIZONTAL ? height : width;
    track_pos[c1] = (orientation == HORIZONTAL ? left : top) + (hasButtons ? (button_size[c1] + gap) : 0.0);
    track_pos[c2] = orientation == HORIZONTAL ? top : left;

    degraded = track_size[c1] < 1.0;  // gracefull degradation at paranormal sizes
    if (degraded)
    {
      if (hasButtons && track_size[c1] < -2.0 * gap)
      {
        button_size[c1] = (orientation == HORIZONTAL ? width : height) / 2.0;
        button_plus_pos[c1] = (orientation == HORIZONTAL ? (left + width) : (top + height)) - button_size[c1];
      }
    }

    updateExtent();
    knob_size[c2] = track_size[c2];

    updateComp();
    comp[c2] = 0.0;
  }

  void draw()
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

  void drawButton(float l, float t, int dir, boolean isLocked)
  {
    static final float[][] m = {{1.5f, 3.0f, 3.0f, 2.0f, 1.5f, 1.5f}, {3.0f, 3.0f, 1.5f, 2.0f, 3.0f, 1.5f}, {3.0f, 1.5f, 2.0f, 3.0f, 1.5f, 1.5f}, {3.0f, 3.0f, 2.0f, 1.5f, 1.5f, 3.0f}};

    stroke(color1);
    fill(isLocked ? color1 : color2);
    rectMode(CORNER);
    rect(l, t, button_size[0] - 1.0, button_size[1] - 1.0);

    stroke(isLocked ? color2 : color1);
    beginShape(LINE_STRIP);
    vertex(l + button_size[0] / m[dir][0], t + button_size[1] / m[dir][1]);
    vertex(l + button_size[0] / m[dir][2], t + button_size[1] / m[dir][3]);
    vertex(l + button_size[0] / m[dir][4], t + button_size[1] / m[dir][5]);
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
    rect(track_pos[0] + comp[0], track_pos[1] + comp[1], knob_size[0] - 1.0, knob_size[1] - 1.0);
  }
}
