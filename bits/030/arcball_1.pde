// ARCBALL_1
// by arielm - June 23, 2003
// http://www.chronotext.org

// keep 'x', 'y' or 'z' pressed in order to constrain to one of the axis

/* CREDITS...
1) v3ga for starting with quaternions in processing!
http://proce55ing.net/discourse/yabb/YaBB.cgi?board=Tools;action=display;num=1054894944

2) Paul Rademacher & other contributors to the GLUI User Interface Library
http://www.cs.unc.edu/~rademach/glui

3) Nick Bobic (great introductionary article on quaternions + source code)
http://www.gamasutra.com/features/19980703/quaternions_01.htm

4) Matrix and Quaternion FAQ
http://skal.planet-d.net/demo/matrixfaq.htm

5) Ken Shoemake, inventor of the ArcBall concept, around 1985 (?)...
*/


ArcBall arcball;

int[] colors;

void setup()
{
  size(400, 400);
  background(0xff66c0ff);

  colors = new int[] { 0xffc0c0c0, 0xffffc000, 0xff66c033, 0xff669933, 0xffff9900, 0xff999999 };

  arcball = new ArcBall(width / 2.0f, height / 2.0f, min(width - 20, height - 20) / 2.0f);
}

void mousePressed()
{
  arcball.mousePressed();
}

void mouseDragged()
{
  arcball.mouseDragged();
}

void keyPressed()
{
  switch(key)
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

void keyReleased()
{
    arcball.axis = -1;
}

void loop()
{
  translate(200.0f, 200.0f, 0.0f);  // positioning...

  arcball.run(); // this one should be placed after you are positioned and before you draw

  noStroke();
  cube(160.0f, colors); // drawing...
  
  // showing the silouhette of the ArcBall, for debugging purposes only...
  resetMatrix();
  ellipseMode(CENTER_RADIUS);
  stroke(0);
  noFill();
  ellipse(arcball.center_x, arcball.center_y, arcball.radius, arcball.radius);
}

// ---

public void cube(float d, int[] col)
{
  d /= 2.0f;

  push();

  fill(col[0]);
  face(d);  // 5, 7, 3, 1
  rotateY(HALF_PI);

  fill(col[1]);
  face(d);  // 4, 5, 7, 6
  rotateY(HALF_PI);

  fill(col[2]);
  face(d);  // 4, 0, 2, 6
  rotateY(HALF_PI);

  fill(col[3]);
  face(d);  // 0, 2, 3, 1
  rotateX(HALF_PI);

  fill(col[4]);
  face(d);  // 0, 4, 5, 1
  rotateX(PI);

  fill(col[5]);
  face(d);  // 2, 3, 7, 6

  pop();
}

void face(float d)
{
  beginShape(POLYGON);
  vertex(-d, -d, +d);
  vertex(+d, -d, +d);
  vertex(+d, +d, +d);
  vertex(-d, +d, +d);
  endShape();
}

// ---

class ArcBall
{
  float center_x, center_y, radius;
  Vec3 v_down, v_drag;
  Quat q_now, q_down, q_drag;
  Vec3[] axisSet;
  int axis;

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

    axisSet = new Vec3[] {new Vec3(1.0f, 0.0f, 0.0f), new Vec3(0.0f, 1.0f, 0.0f), new Vec3(0.0f, 0.0f, 1.0f)};
    axis = -1;  // no constraints...
  }

  void mousePressed()
  {
    v_down = mouse_to_sphere(mouseX, mouseY);
    q_down.set(q_now);
    q_drag.reset();
  }

  void mouseDragged()
  {
    v_drag = mouse_to_sphere(mouseX, mouseY);
    q_drag.set(Vec3.dot(v_down, v_drag), Vec3.cross(v_down, v_drag));
  }

  void run()
  {
    q_now = Quat.mul(q_drag, q_down);
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
