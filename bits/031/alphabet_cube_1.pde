// ALPHABET CUBE 1
// by arielm - June 24, 2003
// http://www.chronotext.org

// keep 'x', 'y' or 'z' pressed in order to constrain to one of the axis


Grid grid;
Controller controller;
Cube cube;
ArcBall arcball;

int[] colors;

void setup()
{
  size(400, 400);
  framerate(25);
  background(0xff66c0ff);

  colors = new int[]
  { 
    0xffc0c0c0,
    0xffffc000,
    0xff66c033,
    0xff669933,
    0xffff9900,
    0xff999999
  };

  BImage[] images =
  {
    loadImage("alef.gif"),
    loadImage("bet.gif"),
    loadImage("gimel.gif"),
    loadImage("dalet.gif"),
    loadImage("he.gif"),
    loadImage("vav.gif")
  };

  grid = new Grid(328.0f, 344.0f, colors);

  controller = new Controller();

  cube = new Cube(120.0f, colors, images);

  arcball = new ArcBall(width / 2.0f, height / 2.0f, min(width - 16, height - 16) / 2.0f);
}

void mousePressed()
{
  arcball.mousePressed();
}

void mouseDragged()
{
  arcball.mouseDragged();
}

void loop()
{
  beginCamera();
  perspective(36.0f, 1.0f, 1.0f, 1000.0f);
  translate(0.0f, 0.0f, -350f);
  endCamera();

  grid.run();
  controller.run();
  arcball.run(); // this one should be placed after matrix operations and before drawing operations
  cube.run();

  resetMatrix();
  grid.draw();
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
  
  final int grid_w = 4;
  final int grid_h = 3;

  final float cell_w = 16.0f;
  final float cell_h = 16.0f;

  float x, y;
  int[] colors;
  boolean over, over_cell, locked;
  int over_cell_index;

  Grid(float x, float y, int[] colors)
  {
    this.x = x;
    this.y = y;
    this.colors = colors;
  }

  void run()
  {
    over = mouseX >= x && mouseX < (x + grid_w * cell_w) && mouseY >= y && mouseY < (y + grid_h * cell_h);
    
    if (over)
    {
      int index = (int) (floor((mouseX - x) / cell_w) + floor((mouseY - y) / cell_h) * grid_w);
      if (grid[index] != -1)
      {
        over_cell = true;
        over_cell_index = grid[index];
      }
      else
      {
        over_cell = false;
      }
    }

    over_cell = over_cell && over;

    if (!locked && over_cell && mousePressed)
    {
      controller.beginInterpolation(over_cell_index);
      locked = true;
    }

    locked = locked && mousePressed;
  }

  void draw()
  {
    int cell;

    for (int i = 0; i < grid_w; i++)
    {
      for (int j = 0; j < grid_h; j++)
      {
        cell = j * grid_w + i;
        if (grid[cell] != -1)
        {
          rectMode(CORNER);
          stroke(0);
          fill(colors[grid[cell]]);
          rect(-1.0f + x + i * cell_w, -1.0f + y + j * cell_h, cell_w, cell_h);

          if (over_cell && over_cell_index == grid[cell])
          {
            rectMode(CENTER_DIAMETER);
            noStroke();
            fill(0);
            rect(x + cell_w * (i + 0.5f), y + cell_h * (j + 0.5f), cell_w / 4.0f, cell_h / 4.0f);
          }
        }
      }
    }
  }
}

// ---

class Controller
{
  final float vomega = 5.0f * DEG_TO_RAD; // angular velocity in radians per frame when interpolating...
  float omega, cosom, sinom;
  float domega;
  float sign;
  Quat from, to;
  boolean interpolating;

  void run()
  {
    interpolator();
    constrainer();
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
}

// ---

class Cube
{
  float size;
  int[] colors;
  BImage[] images;

  // defining one quaternion (that will be used by the interpolator) for each face
  final float SQPI = 0.70710678f; // sin(QUARTER_PI)
  final Quat[] faces =
  {  
    new Quat(+1.0f, +0.0f, +0.0f, +0.0f),
    new Quat(-SQPI, +0.0f, +SQPI, +0.0f),
    new Quat(+0.0f, +0.0f, +1.0f, +0.0f),
    new Quat(+SQPI, +0.0f, +SQPI, +0.0f),
    new Quat(+0.5f, -0.5f, +0.5f, -0.5f),
    new Quat(-0.5f, -0.5f, -0.5f, -0.5f)
  };

  Cube(float size, int[] colors, BImage[] images)
  {
    this.size = size;
    this.colors = colors;
    this.images = images;
  }

  void run()
  {
    noStroke(); // uncomment me to see the quad-patches!
    draw();
  }

  void draw()
  {
    float c; // will hold (z only) cross product for each face, using 3 points: (x2-x1)*(y1-y3)-(y2-y1)*(x1-x3)

    float d = size / 2.0f;

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

    push();

    c = (x[5] - x[4]) * (y[4] - y[2]) - (y[5] - y[4]) * (x[4] - x[2]);
    if (c < 0.0)
    {
      fill(colors[0]);
      face(d, images[0], 1); // 5, 7, 3, 1
    }
    rotateY(HALF_PI);

    c = (x[4] - x[3]) * (y[3] - y[5]) - (y[4] - y[3]) * (x[3] - x[5]);
    if (c > 0.0)
    {
      fill(colors[1]);
      face(d, images[1], 1); // 4, 5, 7, 6
    }
    rotateY(HALF_PI);

    c = (x[0] - x[3]) * (y[3] - y[1]) - (y[0] - y[3]) * (x[3] - x[1]);
    if (c < 0.0)
    {
      fill(colors[2]);
      face(d, images[2], 1); // 4, 0, 2, 6
    }
    rotateY(HALF_PI);

    c = (x[1] - x[0]) * (y[0] - y[2]) - (y[1] - y[0]) * (x[0] - x[2]);
    if (c > 0.0)
    {
      fill(colors[3]);
      face(d, images[3], 1); // 0, 2, 3, 1
    }
    rotateX(HALF_PI);

    c = (x[3] - x[0]) * (y[0] - y[4]) - (y[3] - y[0]) * (x[0] - x[4]);
    if (c < 0.0)
    {
      fill(colors[4]);
      face(d, images[4], 1); // 0, 4, 5, 1
    }
    rotateX(PI);

    c = (x[2] - x[1]) * (y[1] - y[5]) - (y[2] - y[1]) * (x[1] - x[5]);
    if (c < 0.0)
    {
      fill(colors[5]);
      face(d, images[5], 1); // 2, 3, 7, 6
    }

    pop();
  }

  void face(float d, BImage img, int divs)
  {
    // using a quad-patch for more accurate texture-mapping...

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

  ArcBall(float center_x, float center_y, float radius)
  {
    this.center_x = center_x;
    this.center_y = center_y;
    this.radius = radius;

    v_down = new Vec3();
    v_drag = new Vec3();

    q_now = new Quat();
    q_down = new Quat();
    q_drag = new Quat();

    axis = -1; // no constraints...

    interactive = true;
  }

  void mousePressed()
  {
    if (interactive)
    {
      v_down = mouse_to_sphere(mouseX, mouseY);
      q_down.set(q_now);
      q_drag.reset();

      locked = true;
    }
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
    locked = locked && interactive && mousePressed;

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
    Vec3 res = new Vec3();
    res.sub(vector, Vec3.mul(axis, Vec3.dot(axis, vector)));
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

  void sub(Vec3 v1, Vec3 v2)
  {
    x = v1.x - v2.x;
    y = v1.y - v2.y;
    z = v1.z - v2.z;
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
