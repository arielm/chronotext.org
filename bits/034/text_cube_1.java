// TEXT CUBE 1
// by arielm - July 16 2003
// http://www.chronotext.org

import java.util.*;

public class text_cube_1 extends BApplet
{
  UI ui;
  Grid grid;
  CubeController cubeController;
  Cube cube;
  ArcBall arcball;

  static final int w = 800;
  static final int h = 800;
  static final int margin_left = 16;
  static final int margin_top = 16;
  static final int margin_right = 16;
  static final int margin_bottom = 16;

  int[] colors =
  { 
    0xffe4d1be,
    0xffffd000,
    0xff89d525,
    0xff8bae28,
    0xffffa900,
    0xffbdaa95
  };

  String[] sources =
  {
    "text_1.txt",
    "text_2.txt",
    "text_3.txt",
    "text_4.txt",
    "text_5.txt",
    "text_6.txt"
  };

  BImage[] images = new BImage[6];
  Text[] text = new Text[6];
  XFont font;

  TextController textController;

  ScrollBar[] scrollbars = new ScrollBar[6];
  int[] scrollTop = {0, 0, 0, 0, 0, 0};
  int[] prevScrollTop = {-1, -1, -1, -1, -1, -1};

  void setup()
  {
    size(464, 464);
    framerate(20);
    background(0xff8bd1ff);

    // ---

    FontManager fm = new FontManager(10);
    font = fm.getFont("Meta-Bold.vlw.gz", XFont.RGB_BW);
    font.setLeading(1.25f);

    for (int i = 0; i < 6; i++)
    {
      images[i] = createBuffer(w, h, RGB, 0x00ffffff);

      text[i] = new Text();
      text[i].load(sources[i]);
      text[i].wordwrap(font, w - margin_left - margin_right);

      float min = 0.0f;
      float extent = h - margin_top - margin_bottom;
      float max = max(extent, text[i].getHeight(font, text[i].lines.size()));
      float dummy = 0.0f;
      scrollbars[i] = new ScrollBar(width - 4.0f, dummy, 16.0f, dummy, ScrollBar.RIGHT, ScrollBar.TOP, ScrollBar.VERTICAL, min, max, scrollTop[i], extent, color(0, 0, 0), colors[i], true);
      scrollbars[i].setUnitIncrement(font.bodyHeight * font.leading);
      scrollbars[i].setVisible(false);
    }

    // ---

    ui = new UI();

    textController = new TextController(4.0f);

    grid = new Grid(4.0f, 411.0f, colors);

    cubeController = new CubeController();

    cube = new Cube(120.0f, colors, images, 4);

    arcball = new ArcBall(width / 2.0f, height / 2.0f, min(width - 16, height - 16) / 2.0f, new Quat(0.91738033f, 0.0f, -0.39783397f, 0.0f));
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

  void mousePressed()
  {
    grid.mousePressed();
    for (int i = 0; i < 6; i++)
    {
      scrollbars[i].mousePressed();
    }
    arcball.mousePressed();

    ui.getLock(this); // useless, because arcball is monopolizing all the surface anyway...
  }

  void mouseReleased()
  {
    grid.mouseReleased();
    for (int i = 0; i < 6; i++)
    {
      scrollbars[i].mouseReleased();
    }
    arcball.mouseReleased();

    ui.releaseLock(this); // useless, because arcball is monopolizing all the surface anyway...
  }

  void mouseMoved()
  {
    grid.mouseMoved();
  }

  void mouseDragged()
  {
    grid.mouseMoved();
    arcball.mouseDragged();
  }

  void loop()
  {
    beginCamera();
    perspective(36.0f, 1.0f, 1.0f, 1000.0f);
    translate(0.0f, 0.0f, -350f);
    endCamera();

    for (int i = 0; i < 6; i++)
    {
      scrollbars[i].run();
    }

    for (int i = 0; i < 6; i++)
    {
      scrollTop[i] = (int) round(scrollbars[i].getValue());
      if (prevScrollTop[i] != scrollTop[i])
      {
        int curLine = text[i].getLineFromHeight(font, scrollTop[i]);
        int curLineTop = text[i].getLineTop(font, curLine);
        font.drawLines(images[i], text[i].data, text[i].lines, curLine, curLineTop - scrollTop[i], margin_left, margin_top, w - margin_left - margin_right, h - margin_top - margin_bottom, true);
      }
      prevScrollTop[i] = scrollTop[i];
    }

    cubeController.run();
    arcball.run();  // should be placed after matrix operations and before 3d drawing operations!
    cube.draw();
    textController.run();

    resetMatrix();  // from here, we just need plain 2d, drawn on top...

    grid.draw();
    for (int i = 0; i < 6; i++)
    {
      scrollbars[i].draw();
    }
  }

  // ---

  class UI
  {
    Object locker;
    boolean locked;

    UI()
    {
      locker = null;
      locked = false;
    }

    boolean isLocked()
    {
      return locked;
    }

    boolean getLock(Object o)
    {
      if (!locked)
      {
        locker = o;
        locked = true;
        return true;
      }
      else
      {
        return false;
      }
    }

    boolean releaseLock(Object o)
    {
      if (locker == o)
      {
        locker = null;
        locked = false;
        return true;
      }
      else
      {
        return false;
      }
    }
  }

  // ---
  
  class Grid
  {
    final int[] grid =
    {
      -1, -1, -1, +4,
      +0, +1, +2, +3,
      -1, -1, -1, +5
    };
    
    static final int grid_w = 4;
    static final int grid_h = 3;

    static final float cell_w = 16.0f;
    static final float cell_h = 16.0f;

    float x, y;
    int[] colors;
    boolean over_cell, locked;
    int over_cell_index;

    Grid(float x, float y, int[] colors)
    {
      this.x = x;
      this.y = y;
      this.colors = colors;
    }

    void mousePressed()
    {
      if (over_cell && ui.getLock(this))
      {
        locked = true;
        cubeController.beginInterpolation(over_cell_index);
      }
    }

    void mouseReleased()
    {
      ui.releaseLock(this);
      locked = false;
    }

    void mouseMoved()
    {
      over_cell = false;
      boolean over = mouseX >= x && mouseX < (x + grid_w * cell_w) && mouseY >= y && mouseY < (y + grid_h * cell_h);

      if (over)
      {
        int index = (int) (floor((mouseX - x) / cell_w) + floor((mouseY - y) / cell_h) * grid_w);
        if (grid[index] != -1)
        {
          over_cell = true;
          over_cell_index = grid[index];
        }
      }
    }

    void draw()
    {
      for (int i = 0; i < grid_w; i++)
      {
        for (int j = 0; j < grid_h; j++)
        {
          int cell = j * grid_w + i;
          if (grid[cell] != -1)
          {
            rectMode(CORNER);
            stroke(0);
            fill(colors[grid[cell]]);
            rect(x + i * cell_w, y + j * cell_h, cell_w, cell_h);

            if (over_cell && over_cell_index == grid[cell] && !ui.isLocked())
            {
              rectMode(CENTER_DIAMETER);
              noStroke();
              fill(0);
              rect(1.0f + x + cell_w * (i + 0.5f), 1.0f + y + cell_h * (j + 0.5f), cell_w / 4.0f, cell_h / 4.0f);
            }
          }
        }
      }
    }
  }

  // ---
  
  class CubeController
  {
    static final float vomega = 5.0f * DEG_TO_RAD; // angular velocity in radians per frame when interpolating...
    float omega, cosom, sinom;
    float domega;
    float sign;
    Quat from, to;
    boolean interpolating;

    void run()
    {
      interpolator();
      constrainer();
      smoother();
    }

    void interpolator()
    {
      if (interpolating)
      {
        domega = min(domega + 0.5f * vomega, omega);

        float scale0 = sin(omega - domega) / sinom;
        float scale1 = sin(domega) / sinom * sign;

        arcball.q_now.x = scale0 * from.x + scale1 * to.x;
        arcball.q_now.y = scale0 * from.y + scale1 * to.y;
        arcball.q_now.z = scale0 * from.z + scale1 * to.z;
        arcball.q_now.w = scale0 * from.w + scale1 * to.w;

        arcball.q_now.normalize();

        if (domega >= omega)
        {
          interpolating = false;
          arcball.interactive = true;
          arcball.q_down.set(arcball.q_now);
          arcball.q_drag.reset();
        }
      }
    }

    void beginInterpolation(int target)
    {
      from = new Quat(arcball.q_now);
      to = new Quat(cube.faces[target]);

      cosom = from.x * to.x + from.y * to.y + from.z * to.z + from.w * to.w;
      if (cosom < 0.0f)
      {
        cosom = -cosom;
        sign = -1.0f;
      }
      else
      {
        sign = 1.0f;
      }

      if ((1.0f - cosom) < EPSILON)
      {
        return; // the 2 quats are too close...
      }

      omega = (float) Math.acos(cosom);
      sinom = sin(omega);

      domega = 0.0f;
      interpolating = true;
      arcball.interactive = false;
    }

    void constrainer()
    {
      if (arcball.interactive && keyPressed)
      {
        switch (key)
        {
          case 'x':
            arcball.axis = 0;
            break;

          case 'y':
            arcball.axis = 1;
            break;

          case 'z':
            arcball.axis = 2;
            break;
        }
      }
      else
      {
        arcball.axis = -1;
      }
    }

    void smoother()
    {
      if (interpolating || arcball.locked)
      {
        unhint(SMOOTH_IMAGES);
      }
      else
      {
        hint(SMOOTH_IMAGES);
      }
    }
  }

  // ---
  
  class TextController
  {
    float h, gap;
    Vector visibleScrollBars;

    TextController(float gap)
    {
      h = height - 8.0f; // hardcoded!..
      this.gap = gap;
      visibleScrollBars = new Vector(3);
    }

    void run()
    {
      // pass 1: removing previously visible scrollbars from the visibility list
      for (int i = 0; i < 6; i++)
      {
        int visibleIndex = getScrollBarVisibleIndex(new Integer(i));
        if (visibleIndex != -1 && cube.ratios[i] == 0.0f)
        {
          scrollbars[i].setVisible(false);
          visibleScrollBars.removeElementAt(visibleIndex);
        }
      }

      // pass 2: adding newly visible ones...
      for (int i = 0; i < 6; i++)
      {
        int visibleIndex = getScrollBarVisibleIndex(new Integer(i));
        if (visibleIndex == -1 && cube.ratios[i] != 0.0f)
        {
          scrollbars[i].setVisible(true);
          visibleScrollBars.addElement(new Integer(i));
        }
      }

      int n = visibleScrollBars.size();
      if (n > 0)
      {
        // pass 3: adjusting sizes and positions for the visible scrollbars...
        // (not really using the cube-faces-ratios at this time...)

        float availableH = h - (float) max(0, n - 1) * gap;
        float scrollBarH = floor(availableH / (float) n);

        getVisibleScrollBar(0).setY(4.0f);
        getVisibleScrollBar(0).setHeight(scrollBarH);
        getVisibleScrollBar(0).setVerticalAlign(AbstractSlider.TOP);

        if (visibleScrollBars.size() > 1)
        {
          getVisibleScrollBar(n - 1).setY(height - 4.0f);
          getVisibleScrollBar(n - 1).setHeight(scrollBarH);
          getVisibleScrollBar(n - 1).setVerticalAlign(AbstractSlider.BOTTOM);
        }

        if (visibleScrollBars.size() > 2)
        {
          getVisibleScrollBar(1).setY(height / 2.0f);
          getVisibleScrollBar(1).setHeight(scrollBarH);
          getVisibleScrollBar(1).setVerticalAlign(AbstractSlider.CENTER);
        }
      }
    }

    int getScrollBarVisibleIndex(Integer scrollBarIndex)
    {
      for (int i = 0; i < visibleScrollBars.size(); i++)
      {
        if (scrollBarIndex.equals((Integer) visibleScrollBars.elementAt(i)))
        {
          return i;
        }
      }
      return -1;
    }

    ScrollBar getVisibleScrollBar(int visibleIndex)
    {
      return scrollbars[((Integer) visibleScrollBars.elementAt(visibleIndex)).intValue()];
    }
  }

  // ---

  class Cube
  {
    float size, d;
    int[] colors;
    BImage[] images;
    int divs; // number of divisions (>=1) for the quad-patch...

    // defining one quaternion (that will be used by the interpolator) for each face
    static final float SQPI = 0.70710678f; // sin(QUARTER_PI)
    final Quat[] faces =
    {  
      new Quat(+1.0f, +0.0f, +0.0f, +0.0f),
      new Quat(-SQPI, +0.0f, +SQPI, +0.0f),
      new Quat(+0.0f, +0.0f, +1.0f, +0.0f),
      new Quat(+SQPI, +0.0f, +SQPI, +0.0f),
      new Quat(+0.5f, -0.5f, +0.5f, -0.5f),
      new Quat(-0.5f, -0.5f, -0.5f, -0.5f)
    };

    float[] ratios = new float[6];

    Cube(float size, int[] colors, BImage[] images, int divs)
    {
      this.size = size;
      this.colors = colors;
      this.images = images;
      this.divs = divs;

      d = size / 2.0f;
    }

    void draw()
    {
      float cross; // will hold (z only) cross product for each face, using 3 points: (x2-x1)*(y1-y3)-(y2-y1)*(x1-x3)

      // the cube is made of 8 vertices, but we only need 6 of them for hidden-face removal...
      float[] x = {
        screenX(-d, -d, -d),  // 0
        screenX(-d, +d, -d),  // 2
        screenX(-d, +d, +d),  // 3
        screenX(+d, -d, -d),  // 4
        screenX(+d, -d, +d),  // 5
        screenX(+d, +d, +d)   // 7
      };
      float[] y = {
        screenY(-d, -d, -d),  // 0
        screenY(-d, +d, -d),  // 2
        screenY(-d, +d, +d),  // 3
        screenY(+d, -d, -d),  // 4
        screenY(+d, -d, +d),  // 5
        screenY(+d, +d, +d)   // 7
      };

      float[] tmp = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f}; // used to compute a visibility ratio for each face

      push();

      cross = (x[5] - x[4]) * (y[4] - y[2]) - (y[5] - y[4]) * (x[4] - x[2]);
      if (cross < 0.0)
      {
        fill(colors[0]);
        face(images[0]); // 5, 7, 3, 1
        tmp[0] = abs(cross);
      }
      rotateY(HALF_PI);

      cross = (x[4] - x[3]) * (y[3] - y[5]) - (y[4] - y[3]) * (x[3] - x[5]);
      if (cross > 0.0)
      {
        fill(colors[1]);
        face(images[1]); // 4, 5, 7, 6
        tmp[1] = abs(cross);
      }
      rotateY(HALF_PI);

      cross = (x[0] - x[3]) * (y[3] - y[1]) - (y[0] - y[3]) * (x[3] - x[1]);
      if (cross < 0.0)
      {
        fill(colors[2]);
        face(images[2]); // 4, 0, 2, 6
        tmp[2] = abs(cross);
      }
      rotateY(HALF_PI);

      cross = (x[1] - x[0]) * (y[0] - y[2]) - (y[1] - y[0]) * (x[0] - x[2]);
      if (cross > 0.0)
      {
        fill(colors[3]);
        face(images[3]); // 0, 2, 3, 1
        tmp[3] = abs(cross);
      }
      rotateX(HALF_PI);

      cross = (x[3] - x[0]) * (y[0] - y[4]) - (y[3] - y[0]) * (x[0] - x[4]);
      if (cross < 0.0)
      {
        fill(colors[4]);
        face(images[4]); // 0, 4, 5, 1
        tmp[4] = abs(cross);
      }
      rotateX(PI);

      cross = (x[2] - x[1]) * (y[1] - y[5]) - (y[2] - y[1]) * (x[1] - x[5]);
      if (cross < 0.0)
      {
        fill(colors[5]);
        face(images[5]); // 2, 3, 7, 6
        tmp[5] = abs(cross);
      }

      pop();

      // computing the visiblity ratios (between 0.0 and 1.0) for each face...
      float maxValue = 0.0f;
      int maxIndex = 0;
      for(int i = 0; i < 6; i++)
      {
        if (tmp[i] > maxValue)
        {
          maxValue = tmp[i];
          maxIndex = i;
        }
      }
      for (int i = 0; i < 6; i++)
      {
        if (i == maxIndex)
        {
          ratios[i] = 1.0f;
        }
        else if (tmp[i] != 0.0f)
        {
          ratios[i] = tmp[i] / maxValue;
        }
        else
        {
          ratios[i] = 0.0f;
        }
      }
    }

    void face(BImage img)
    {
      // using a patch of divs*divs quads for less deformed texture-mapping...

      noStroke(); // uncomment-me to see the patches ;)

      boolean b;
      float dd = 2.0f * d / divs;
      float du = img.width / divs;
      float dv = img.height / divs;

      for (int i = 0; i < divs; i++)
      {
        b = true;
        beginShape(QUAD_STRIP);
        textureImage(img);
        for (int j = 0; j <= divs; j++)
        {
          b = !b;
          for (int k = 0; k < 2; k++)
          {
            b = !b;
            vertexTexture(j * du , b ? (i * dv) : (i * dv + dv));
            vertex(-d + j * dd, b ? (-d + i * dd) : (-d + i * dd + dd), d);
          }
        }
        endShape();
      }
    }
  }

  // ---

  class ArcBall
  {
    float center_x, center_y, radius;
    Vec3 v_down, v_drag;
    Quat q_now, q_down, q_drag;

    int axis;
    final Vec3[] axisSet =
    {
      new Vec3(1.0f, 0.0f, 0.0f),
      new Vec3(0.0f, 1.0f, 0.0f),
      new Vec3(0.0f, 0.0f, 1.0f)
    };

    boolean locked, interactive;

    ArcBall(float center_x, float center_y, float radius, Quat start)
    {
      this.center_x = center_x;
      this.center_y = center_y;
      this.radius = radius;

      v_down = new Vec3();
      v_drag = new Vec3();

      q_now = start;
      q_down = new Quat(q_now);
      q_drag = new Quat();

      axis = -1; // no constraints...

      interactive = true;
    }

    void mousePressed()
    {
      if (interactive && ui.getLock(this))
      {
        v_down = mouse_to_sphere(mouseX, mouseY);
        q_down.set(q_now);
        q_drag.reset();

        locked = true;
      }
    }

    void mouseReleased()
    {
      ui.releaseLock(this);
      locked = false;
    }

    void mouseDragged()
    {
      if (interactive && locked)
      {
        v_drag = mouse_to_sphere(mouseX, mouseY);
        q_drag.set(Vec3.dot(v_down, v_drag), Vec3.cross(v_down, v_drag));
      }
    }

    void run()
    {
      locked = locked && interactive;

      if (interactive)
      {
        q_now = Quat.mul(q_drag, q_down);
      }

      applyQuat2Matrix(q_now);
    }

    Vec3 mouse_to_sphere(float x, float y)
    {
      Vec3 v = new Vec3();
      v.x = (x - center_x) / radius;
      v.y = (y - center_y) / radius;

      float mag = v.x * v.x + v.y * v.y;
      if (mag > 1.0f)
      {
        v.normalize();
      }
      else
      {
        v.z = sqrt(1.0f - mag);
      }

      return (axis == -1) ? v : constrain_vector(v, axisSet[axis]);
    }

    Vec3 constrain_vector(Vec3 vector, Vec3 axis)
    {
      Vec3 res = Vec3.sub(vector, Vec3.mul(axis, Vec3.dot(axis, vector)));
      res.normalize();
      return res;
    }

    void applyQuat2Matrix(Quat q)
    {
      // instead of transforming q into a matrix and applying it...

      float[] aa = q.getValue();
      rotate(aa[0], aa[1], aa[2], aa[3]);
    }
  }

  static class Vec3
  {
    float x, y, z;

    Vec3()
    {
    }

    Vec3(float x, float y, float z)
    {
      this.x = x;
      this.y = y;
      this.z = z;
    }

    void normalize()
    {
      float length = length();
      x /= length;
      y /= length;
      z /= length;
    }

    float length()
    {
      return (float) Math.sqrt(x * x + y * y + z * z);
    }

    static Vec3 cross(Vec3 v1, Vec3 v2)
    {
      Vec3 res = new Vec3();
      res.x = v1.y * v2.z - v1.z * v2.y;
      res.y = v1.z * v2.x - v1.x * v2.z;
      res.z = v1.x * v2.y - v1.y * v2.x;
      return res;
    }

    static float dot(Vec3 v1, Vec3 v2)
    {
      return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
    }

    static Vec3 mul(Vec3 v, float d)
    {
      Vec3 res = new Vec3();
      res.x = v.x * d;
      res.y = v.y * d;
      res.z = v.z * d;
      return res;
    }

    static Vec3 sub(Vec3 v1, Vec3 v2)
    {
      Vec3 res = new Vec3();
      res.x = v1.x - v2.x;
      res.y = v1.y - v2.y;
      res.z = v1.z - v2.z;
      return res;
    }
  }

  static class Quat
  {
    float w, x, y, z;

    Quat()
    {
      reset();
    }

    Quat(float w, float x, float y, float z)
    {
      this.w = w;
      this.x = x;
      this.y = y;
      this.z = z;
    }
    
    Quat(Quat q)
    {
      set(q);
    }

    void reset()
    {
      w = 1.0f;
      x = 0.0f;
      y = 0.0f;
      z = 0.0f;
    }

    void set(float w, Vec3 v)
    {
      this.w = w;
      x = v.x;
      y = v.y;
      z = v.z;
    }

    void set(Quat q)
    {
      w = q.w;
      x = q.x;
      y = q.y;
      z = q.z;
    }

    void normalize()
    {
      float square = x * x + y * y + z * z + w * w;
      float dist = (square > 0.0f) ? (1.0f / (float) Math.sqrt(square)) : 1.0f;

      x *= dist;
      y *= dist;
      z *= dist;
      w *= dist;
    }

    static Quat mul(Quat q1, Quat q2)
    {
      Quat res = new Quat();
      res.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
      res.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
      res.y = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z;
      res.z = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x;
      return res;
    }

    float[] getValue()
    {
      // transforming this quat into an angle and an axis vector...

      float[] res = new float[4];

      float sa = (float) Math.sqrt(1.0f - w * w);
      if (sa < EPSILON)
      {
        sa = 1.0f;
      }

      res[0] = (float) Math.acos(w) * 2.0f;
      res[1] = x / sa;
      res[2] = y / sa;
      res[3] = z / sa;

      return res;
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
      int spaceIndex = -2;    // lastToken = 2
      int wordIndex = -2;     // lastToken = 3
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

      clear_ink = (mode == ALPHA || mode == RGB_WB) ? 0x00000000 : 0x00ffffff;

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

  class AbstractSlider extends Observable // v1.3
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
    boolean over, over_track, over_knob;
    boolean locked, track_locked, knob_locked;

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

    void setX(float x)
    {
      setBounds(x, y, width, height);
    }

    void setY(float y)
    {
      setBounds(x, y, width, height);
    }

    void setLocation(float x, float y)
    {
      setBounds(x, y, width, height);
    }

    void setWidth(float width)
    {
      setBounds(x, y, width, height);
    }

    void setHeight(float height)
    {
      setBounds(x, y, width, height);
    }

    void setSize(float width, float height)
    {
      setBounds(x, y, width, height);
    }

    void setHorizontalAlign(int halign)
    {
      setAlign(halign, valign);
    }

    void setVerticalAlign(int valign)
    {
      setAlign(halign, valign);
    }
    
    void setAlign(int halign, int valign)
    {
      this.halign = halign;
      this.valign = valign;
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

  class ScrollBar extends AbstractSlider  // v1.3
  {
    boolean hasButtons;

    float unitIncrement = 1.0f;
    float blockIncrement;
    boolean dirtyBI;
    float[] track_pos = new float[2], track_size = new float[2];
    float[] button_plus_pos = new float[2], button_size = new float[2];
    float direction;
    boolean over_button_minus, over_button_plus;
    boolean button_minus_locked, button_plus_locked;

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

    void mousePressed()
    {
      if (!ui.isLocked() && !degraded && visible && enablable && enabled)
      {
        m_comp[0] = mouseX;
        m_comp[1] = mouseY;

        if (over_button_minus)
        {
          button_minus_locked = true;
          direction = -1.0f;
        }
        else if (over_button_plus)
        {
          button_plus_locked = true;
          direction = 1.0f;
        }
        else if (over_knob)
        {
          knob_locked = true;
          offset = (m_comp[c1] - track_pos[c1] - comp[c1]) * (max - min) / track_size[c1];
        }
        else if (over_track)
        {
          track_locked = true;
          direction = (m_comp[c1] - track_pos[c1] > comp[c1]) ? 1.0f : -1.0f;
        }

        if (button_minus_locked || button_plus_locked || track_locked || knob_locked)
        {
          ui.getLock(this);
          locked = true;
          setValueIsAdjusting(true);
        }
      }
    }

    void mouseReleased()
    {
      setValueIsAdjusting(false);
      ui.releaseLock(this);
      locked = false;
    }

    void run()
    {
      button_minus_locked = visible && enablable && enabled && hasButtons && button_minus_locked && locked;
      button_plus_locked = visible && enablable && enabled && hasButtons && button_plus_locked && locked;
      track_locked = visible && enablable && enabled && track_locked && locked;
      knob_locked = visible && enablable && enabled && knob_locked && locked;

      if (locked && !button_minus_locked && !button_plus_locked && !track_locked && !knob_locked)
      {
        setValueIsAdjusting(false);
        ui.releaseLock(this);
        locked = false;
      }

      m_comp[0] = mouseX;
      m_comp[1] = mouseY;

      over = !degraded && visible && enablable && enabled && m_comp[0] >= left && m_comp[0] < (left + width) && m_comp[1] >= top && m_comp[1] < (top + height);
      over_button_minus = hasButtons && over && (m_comp[0] >= left && m_comp[0] < (left + button_size[0]) && m_comp[1] >= top && m_comp[1] < (top + button_size[1]));
      over_button_plus = hasButtons && over && !over_button_minus && (m_comp[c1] >= button_plus_pos[c1] && m_comp[c1] < (button_plus_pos[c1] + button_size[c1]) && m_comp[c2] >= button_plus_pos[c2] && m_comp[c2] < (button_plus_pos[c2] + button_size[c2]));
      over_track = over && !over_button_minus && !over_button_plus && (m_comp[c1] >= track_pos[c1] && m_comp[c1] < (track_pos[c1] + track_size[c1]) && m_comp[c2] >= track_pos[c2] && m_comp[c2] < (track_pos[c2] + track_size[c2]));
      over_knob = over_track && (m_comp[c1] >= (track_pos[c1] + comp[c1]) && m_comp[c1] < (track_pos[c1] + comp[c1] + knob_size[c1]) && m_comp[c2] >= top && (m_comp[c2] + comp[c2]) < (track_pos[c2] + comp[c2] + knob_size[c2]));

      if (!locked || degraded)
      {
        return;
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