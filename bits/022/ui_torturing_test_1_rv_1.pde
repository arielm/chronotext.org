// UI TORTURING TEST 1, REV 1
// by arielm - May 22, 2003
// http://www.chronotext.org

// REV 1 - May 27, 2003: includes a basic event-posting system...

// Slider is inspired by javax.swing.JSlider
// ScrollBar is inspired by javax.swing.JScrollBar

Slider slider_T, slider_B, slider_L;
ScrollBar scrollbar_R;

float box_min, box_max, box_h;
float sheet_w, sheet_h, sheets_min, sheets_max;
int sheets_n, sheet_selected;
float paper_top, paper_offset;

Controller controller;

float m;

void setup()
{
  size(300, 300);
  framerate(25);
  background(0);

  sheet_w = 50.0;
  sheet_h = 10.0;
  sheets_min = 0.0;
  sheets_max = 20.0;
  sheets_n = 10;
  sheet_selected = 10;
  box_min = 0.0;
  box_max = 100.0;
  box_h = 50.0;
  paper_top = -box_h / 2.0;
  paper_offset = 0.0;

  slider_T = new Slider(8.0, 8.0, 284.0, 9.0, Slider.LEFT, Slider.TOP, Slider.HORIZONTAL, sheets_min, sheets_max, sheets_n, color(255, 255, 255), color(0, 0, 0));
  slider_T.setTickSpacing(1.0);
  slider_T.setPaintTicks(true);
  slider_T.setSnapToTicks(true);

  slider_B = new Slider(292.0, 292.0, 284.0, 9.0, Slider.RIGHT, Slider.BOTTOM, Slider.HORIZONTAL, box_min, box_max, box_h, color(255, 153, 0), color(0, 0, 0));

  slider_L = new Slider(8.0, 150.0, 9.0, 250.0, Slider.LEFT, Slider.CENTER, Slider.VERTICAL, 0.0, sheets_n, sheet_selected, color(255, 102, 0), color(0, 0, 0));
  slider_L.setTickSpacing(1.0);
  slider_L.setPaintTicks(true);
  slider_L.setSnapToTicks(true);

  scrollbar_R = new ScrollBar(292.0, 150.0, 13.0, 250.0, ScrollBar.RIGHT, ScrollBar.CENTER, ScrollBar.VERTICAL, 0.0, sheets_n * sheet_h, 0.0, box_h, color(127, 127, 127), color(51, 51, 51), true);
  scrollbar_R.setUnitIncrement(sheet_h / 10.0);  // it will take 10 frames (pressing a scrollbar button) to move by one sheet...
  //scrollbar_R.setBlockIncrement(sheet_h);  // instead of (by default) moving by the height of the box, the "knob" will move by the height of one sheet (each frame, when pressing on the track, above or under the knob)...

  controller = new Controller();  // controls everything!
  slider_T.addObserver(controller);
  slider_B.addObserver(controller);
  slider_L.addObserver(controller);
  scrollbar_R.addObserver(controller);

  m = 0.0;  // used for rotation and mumbling...
}

void loop()
{
  // leave these 4 lines around the beginning...
  slider_T.run();
  slider_B.run();
  slider_L.run();
  scrollbar_R.run();

  // startMumble();
  slider_T.setSize(abs(284.0 * cos(m)), 9.0);
  slider_L.setSize(9.0, abs(250.0 * sin(m)));
  slider_B.setSize(abs(284.0 * cos(m)), 9.0);
  scrollbar_R.setSize(13.0, abs(250.0 * sin(m)));
  // endMumble();

  beginCamera();
  ortho(-100.0 ,100.0, -100.0, 100.0, 100.0 , -100.0);
  rotateX(radians(15.0));
  rotateY(radians(45.0) + abs(HALF_PI - m));
  endCamera();

  drawBox();
  drawPaper();

  m = (m + radians(1.0)) % PI;

  resetMatrix();  // otherwise, the following should not draw well...

  // leave these 4 lines around the end....
  slider_T.draw();
  slider_B.draw();
  slider_L.draw();
  scrollbar_R.draw();
}

void drawBox()
{
  stroke(255, 153, 0);
  fill(255, 255, 204);
  box(100.0, box_h, 25.0);
}

void drawPaper()
{
  if (sheets_n > 0)
  {
    float y = paper_top + paper_offset;
    float o = 0.0;

    if (sheet_selected > 0)
    {
      stroke(255, 102, 0);
      for (float i = 1.0; i < 4.0; i++)
      {
        line(-sheet_w / 2.0 + i * sheet_w / 4.0, y + sheet_h * (float)(sheet_selected - 1), cos(PI * (float)(sheet_selected - 1)) * sheet_h / 4.0, -sheet_w / 2.0 + i * sheet_w / 4.0, y + sheet_h * (float)sheet_selected, cos(PI * (float)sheet_selected) * sheet_h / 4.0);
      }
    }

    stroke(127);
    fill(255);
    beginShape(QUAD_STRIP);
    for (int i = 0; i <= sheets_n; i++)
    {
      vertex(-sheet_w / 2.0 * cos(o), y, cos(o) * sheet_h / 4.0);
      vertex(sheet_w / 2.0 * cos(o), y, cos(o) * sheet_h / 4.0);

      y += sheet_h;
      o += PI;
    }
    endShape();
  }
}

void keyPressed()  // used only for debugging...
{
  switch(key)
  {
    case 't':
    slider_T.setEnabled(!slider_T.getEnabled());
    break;

    case 'b':
    slider_B.setEnabled(!slider_B.getEnabled());
    break;

    case 'r':
    scrollbar_R.setEnabled(!scrollbar_R.getEnabled());
    break;

    case 'l':
    slider_L.setEnabled(!slider_L.getEnabled());
    break;
  }
}

// ---

class Controller implements Observer
{
  public void update(Observable o, Object arg)
  {
    if (o == slider_T && arg == AbstractSlider.VALUE)
    {
      sheets_n = (int)slider_T.getValue();
      slider_L.setMaximum(sheets_n);
      scrollbar_R.setMaximum(sheets_n * sheet_h);

      paper_top = -box_h / 2.0; 
      scrollbar_R.setExtent(box_h);
    }
    else if (o == slider_B && arg == AbstractSlider.VALUE)
    {
      box_h = slider_B.getValue();
      paper_top = -box_h / 2.0; 
      scrollbar_R.setExtent(box_h);
    }
    else if (o == slider_L && arg == AbstractSlider.VALUE)
    {
      sheet_selected = (int)slider_L.getValue();
    }
    else if (o == scrollbar_R && arg == AbstractSlider.VALUE)
    {
      paper_offset = -scrollbar_R.getValue();

      paper_top = -box_h / 2.0; 
      scrollbar_R.setExtent(box_h);
    }
  }
}

// ---

class AbstractSlider extends Observable
{
  static final String MIN = "min";
  static final String MAX = "max";
  static final String VALUE = "value";
  static final String EXTENT = "extent";

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
    propertyChanged();
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

  void propertyChanged()
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

  void fireNotification(String propertyId)
  {
    setChanged();
    notifyObservers(propertyId);
  }
}

class Slider extends AbstractSlider
{
  float tickSpacing;
  boolean paintTicks, snapToTicks;

  float[] pos = new float[2], size = new float[2];

  Slider(float x, float y, float width, float height, int halign, int valign, int orientation, float min, float max, float value, color color1, color color2)
  {
    super(min, max, value, 0.0);  // extent is not relevant here...

    this.halign = halign;
    this.valign = valign;
    this.orientation = orientation;
    this.color1 = color1;
    this.color2 = color2;

    c1 = orientation;
    c2 = 1 - c1;

    enablable = getIsEnablable();
    setBounds(x, y, width, height);
  }

  void setValue(float n)
  {
    if (snapToTicks)
    {
      n = min + round((n - min) / tickSpacing) * tickSpacing;
    }

    super.setValue(n);
  }

  void setTickSpacing(float spacing)
  {
    tickSpacing = spacing;
  }

  void setPaintTicks(boolean b)
  {
    paintTicks = b;
  }

  void setSnapToTicks(boolean b)
  {
    snapToTicks = b;
  }

  void run()
  {
    knob_locked = knob_locked && enablable && enabled && mousePressed;

    m_comp[0] = mouseX;
    m_comp[1] = mouseY;

    over_track = !degraded && enablable && enabled && !armed && !knob_locked && mousePressed && (m_comp[0] >= pos[0] && m_comp[0] < (pos[0] + size[0]) && m_comp[1] >= pos[1] && m_comp[1] < (pos[1] + size[1]));
    armed = !over_track && mousePressed;

    if (degraded)
    {
      return;
    }

    over_knob = over_track && (m_comp[c1] >= (pos[c1] + comp[c1]) && m_comp[c1] < (pos[c1] + comp[c1] + knob_size[c1]) && m_comp[c2] >= (pos[c2] + comp[c2]) && m_comp[c2] < (pos[c2] + comp[c2] + knob_size[c2]));

    if (over_knob)
    {
      knob_locked = true;
      offset = (m_comp[c1] - pos[c1] - comp[c1]) * (max - min) / (size[c1] - knob_size[c1]);
    }
    else if (over_track)
    {
      setValue(min + (m_comp[c1] - pos[c1] - knob_size[c1] / 2.0) * (max - min) / (size[c1] - knob_size[c1]));
    }

    if (knob_locked)
    {
      setValue((m_comp[c1] - pos[c1]) * (max - min) / (size[c1] - knob_size[c1]) - offset);
    }
  }

  boolean getIsEnablable()
  {
    return max != min;
  }

  void updateComp()
  {
    if (!degraded)
    {
      comp[c1] = !enablable ? 0.0 : (value - min) / (max - min) * (size[c1] - knob_size[c1]);
    }
  }

  void recalc()
  {
    size[c1] = orientation == HORIZONTAL ? width : height;
    size[c2] = orientation == HORIZONTAL ? height : width;
    pos[c1] = orientation == HORIZONTAL ? left : top;
    pos[c2] = orientation == HORIZONTAL ? top : left;

    knob_size[c1] = size[c2];
    knob_size[c2] = size[c2];

    degraded = knob_size[c1] > size[c1];  // gracefull degradation at paranormal sizes

    updateComp();
    comp[c2] = 0.0;
  }

  void draw()
  {
    drawTrack();

    if (!degraded)
    {
      drawKnob();

      if (paintTicks)
      {
        drawTicks();
      }
    }
  }

  void drawTrack()
  {
    noStroke();
    rectMode(CORNER);

    fill(color2);
    rect(pos[0], pos[1], size[0], size[1]);

    fill(color1);
    if (orientation == HORIZONTAL)
    {
      rect(pos[0], pos[1] + size[1] / 2.0, size[0], 1.0);
    }
    else
    {
      rect(pos[0] + size[0] / 2.0, pos[1], 1.0, size[1]);
    }
  }

  void drawTicks()
  {
    float s = tickSpacing / (max - min) * (size[c1] - knob_size[c1]);
    if (s >= 2.0)
    {
      noStroke();
      rectMode(CENTER_DIAMETER);

      float o = pos[c1] + knob_size[c1] / 2.0;
      float i;
      int n_ticks = (int)((max - min) / tickSpacing);
      for (int n = 0; n <= n_ticks; n++)
      {
        i = o + n * s;

        if (knob_locked && i >= pos[c1] + comp[c1] && i < pos[c1] + comp[c1] + knob_size[c1])
        {
          fill(color2);
        }
        else
        {
          fill(color1);
        }

        if (orientation == HORIZONTAL)
        {
          rect(i, pos[1] + size[1] / 2.0, 1.0, size[1] / 3.0);
        }
        else
        {
          rect(pos[0] + size[0] / 2.0, i, size[0] / 3.0, 1.0);
        }
      }
    }
  }

  void drawKnob()
  {
    stroke(color1);
    fill(knob_locked ? color1 : color2);
    rectMode(CORNER);
    rect(pos[0] + comp[0], pos[1] + comp[1], knob_size[0] - 1.0, knob_size[1] - 1.0);
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

