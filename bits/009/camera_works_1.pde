// CAMERA WORKS 1
// by arielm, April 2003
// http://www.chronotext.org

HSlider[] sliders;
HSlider slider_fov, slider_distance, slider_elevation, slider_azimuth, slider_twist;

float fovy, aspect, Znear, Zfar;
float elevation, azimuth, twist, distance;

BFont f;

void setup()
{
  size(300, 300);
  framerate(25);
  background(0);
  hint(SMOOTH_IMAGES);

  distance = 200.0;
  elevation = 300.0;
  azimuth = 0.0;
  twist = 0.0;
  
  fovy = 45.0;
  aspect = (float)width / (float)height;
  Znear = 1.0;  // ?
  Zfar = 1000.0;  // ?

  slider_fov = new HSlider(111.0, 6.0, 180.0, 6.0, 12.0, 102.0, fovy);
  slider_distance = new HSlider(111.0, 18.0, 180.0, 6.0, 120.0, 500.0, distance);
  slider_elevation = new HSlider(111.0, 264.0, 180.0, 6.0, 0.0, 360.0, elevation);
  slider_azimuth = new HSlider(111.0, 276.0, 180.0, 6.0, 0.0, 360.0, azimuth);
  slider_twist = new HSlider(111.0, 288.0, 180.0, 6.0, 0.0, 360.0, twist);

  sliders = new HSlider[] {slider_fov, slider_distance, slider_elevation, slider_azimuth, slider_twist};

  f = loadFont("OCR-B.vlw.gz");
}

void loop()
{
  for (int i = 0; i < sliders.length; i++)
  {
    sliders[i].run();
  }

  fovy = round(slider_fov.value);
  distance = round(slider_distance.value);
  elevation = round(slider_elevation.value);
  azimuth = round(slider_azimuth.value);
  twist = round(slider_twist.value);

  beginCamera();
  perspective(fovy, aspect, Znear, Zfar);
  // custom viewing transformation
    translate(0.0, 0.0, -distance);
    rotateZ(-radians(twist));
    rotateX(-radians(elevation));
    rotateZ(-radians(azimuth));
  endCamera();

  drawObjects();

  for (int i = 0; i < sliders.length; i++)
  {
    sliders[i].draw();
  }

  setFont(f, 13);
  fill(255);
  text("FOV      : " + nf((int)fovy, 3), 6, 13);
  text("DISTANCE : " + nf((int)distance, 3), 6, 25);
  text("ELEVATION: " + nf((int)elevation, 3), 6, 271);
  text("AZIMUTH  : " + nf((int)azimuth, 3), 6, 283);
  text("TWIST    : " + nf((int)twist, 3), 6, 295);
}

// ---

void drawObjects()
{
  drawGrid();
  drawHe();
}

void drawGrid()
{
  stroke(255, 255, 240);
  for (int i = 0; i < 10; i++)
  {
    beginShape(LINES);
    vertex(-45 + i * 10, -45, 0);
    vertex(-45 + i * 10, 45, 0);
    endShape();
    beginShape(LINES);
    vertex(-45, -45 + i * 10, 0);
    vertex(45, -45 + i * 10, 0);
    endShape();
  }
}

void drawHe()
{
  push();
  fill(255, 204, 0);
  stroke(255, 102, 0);
  translate(20.0, 0.0, 5.0);
  box(10.0, 50.0, 10.0);
  translate(-20.0, -20.0, 0.0);
  box(50.0, 10.0, 10.0);
  translate(-20.0, 30.0, 0.0);
  box(10.0, 30.0, 10.0);
  pop();
}

// ---

class HSlider
{
  float left, top;
  float width, height;
  float value_min, value_max, value;
  float x, y;
  float offset_x;
  boolean over, armed, locked;

  HSlider(float _left, float _top, float _width, float _height, float _value_min, float _value_max, float _value)
  {
    left = _left;
    top = _top;
    width = _width;
    height = _height;
    value_min = _value_min;
    value_max = _value_max;
    value = _value;

    x = (value - value_min) / (value_max - value_min) * width;
    y = top + height / 2.0;

    over = false;
    armed = false;
    locked = false;
  }
  
  void run()
  {
    over = mouseX >= (left + x - height / 2.0) && mouseX <= (left + x + height / 2.0) && mouseY >= top && mouseY <= (top + height);

    if (!armed)
    {
        if (!locked && mousePressed)
        {
		if (!over)
		{
          		armed = true;
		}
		else
		{
			locked = true;
                        offset_x = x - mouseX;
		}
        }
        else if (locked && !mousePressed)
        {
          locked = false;
        }
    }
    else if (!mousePressed)
    {
      armed = false;
    }

    if (locked && pmouseX != mouseX)
    {
      x = constrain(mouseX + offset_x, 0.0, width);
      value = value_min + x * (value_max - value_min) / width;
    }
  }

  void draw()
  {
    stroke(255);
    line(left, y, left + width, y);

    stroke(255);
    fill(locked ? 0 : 255);
    rectMode(CENTER_DIAMETER);
    rect(left + x, y, height, height);
  }
}
