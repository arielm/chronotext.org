// HELIX 1
// by arielm, May 2003
// http://www.chronotext.org

// press H to toggle between hypno and normal modes...

float fovy, aspect;
float elevation, azimuth, twist, distance;
float v_azimuth;

float r1, r2, h, turns;

boolean hypno;

HSlider[] sliders;
HSlider slider_elevation, slider_r1, slider_r2, slider_h, slider_turns;

BFont f;

void setup()
{
  size(300,300);
  framerate(25);
  hint(SMOOTH_IMAGES);
  background(0);   

  fovy = 60.0;
  aspect = (float)width / (float)height;

  distance = 300.0;
  elevation = 300.0;  // degrees
  azimuth = 0.0;  // degrees
  twist = 0.0;  // degrees

  v_azimuth = 0.5; // degrees

  hypno = false;

  r1 = 100.0;
  r2 = 0.0;
  h = 75.0;
  turns = 4.0;

  slider_elevation = new HSlider(111.0, 6.0, 180.0, 6.0, 0.0, 360.0, elevation);
  slider_r1 = new HSlider(111.0, 252.0, 180.0, 6.0, 0.0, 200.0, r1);
  slider_r2 = new HSlider(111.0, 264.0, 180.0, 6.0, 0.0, 200.0, r2);
  slider_h = new HSlider(111.0, 276.0, 180.0, 6.0, 0.0, 200.0, h);
  slider_turns = new HSlider(111.0, 288.0, 180.0, 6.0, 1.0, 10.0, turns);

  sliders = new HSlider[] {slider_elevation, slider_r1, slider_r2, slider_h, slider_turns};

  f = loadFont("OCR-B.vlw.gz");
}

void keyPressed()
{
  if (key == 'h' || key == 'H')
  {
    hypno = !hypno;
    if (hypno)
    {
      v_azimuth = -20.0;
      elevation = 180.0;
      r1 = 125.0;
      r2 = 0.0;
      h = 200.0;
      turns = 7.0;
    }
    else
    {
      v_azimuth = 0.5;
    }
  }
}

void loop()
{
  if (!hypno)
  {
    for (int i = 0; i < sliders.length; i++)
    {
      sliders[i].run();
    }

    elevation = round(slider_elevation.value);
    r1 = round(slider_r1.value);
    r2 = round(slider_r2.value);
    h = round(slider_h.value);
    turns = round(slider_turns.value);
  }

  beginCamera();
  perspective(fovy, aspect, 1.0, 1000.0);
  translate(0.0, 0.0, -distance);
  rotateZ(-radians(twist));
  rotateX(-radians(elevation));
  rotateZ(-radians(azimuth));
  endCamera();

  drawHelix(0.0f, 0.0f, 0.0f, turns, r1, r2, h, 5.0f);

  if (!hypno)
  {
    resetMatrix();  // without this one, the sliders won't draw...

    for (int i = 0; i < sliders.length; i++)
    {
      sliders[i].draw();
    }

    setFont(f, 13);
    fill(255);
    text("ELEVATION: " + nf((int)elevation, 3), 6, 13);
    text("RADIUS 1 : " + nf((int)r1, 3), 6, 259);
    text("RADIUS 2 : " + nf((int)r2, 3), 6, 271);
    text("HEIGHT   : " + nf((int)h, 3), 6, 283);
    text("TURNS    : " + nf((int)turns, 3), 6, 295);
  }

  azimuth = (azimuth + v_azimuth) % 360.0;
}

void drawHelix(float x, float y, float z, float turns, float r1, float r2, float h, float dd)
{
  // draws an helix with equidistant points (dd being the distance between each of them)

  float c = TWO_PI * turns;
  float dr = (r2 - r1) / c;
  float dz = h / c;

  float r = r1;
  float d = 0.0;

  stroke(255, 224, 0);
  beginShape(LINE_STRIP);
  do
  {
    vertex(x - sin(d) * r, y + cos(d) * r, z + d * dz);
    d += dd / r;
    r = r1 + d * dr;
  }
  while(d < c);
  endShape();
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
