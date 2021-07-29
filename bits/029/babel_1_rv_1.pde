// BABEL 1, REV 1
// by arielm - JUNE 4, 2003
// http://www.chronotext.org

// REV 1 - june 5, 2003:
// - implemented (as an alternate version) depth using vertex alpha coloring...
// - it works thanks to a workaround for the "smoothed texture mapping" bug...

// text in hebrew from the Bible, Genesis 11:1

float fovy, aspect;
float elevation, azimuth, distance;
float va, aa;

BImage img;
float x, y, z, turns, r1, r2, h, hh, dd;

boolean collapse, exploded;
float v, a;

void setup()
{
  size(300, 400);
  framerate(20.0);
  background(0);

  fovy = 60.0;
  aspect = (float) width / (float) height;

  distance = 260.0;
  elevation = radians(270.0);
  azimuth = radians(235.0);

  va = radians(2.0);
  aa = 0.0;

  // ---

  img = loadImage("genesis 11,1.gif");
  formatImage(img);

  x = 0.0;
  y = 0.0;
  z = -92;
  r1 = 100.0;
  r2 = 50.0;
  h = 200.0;
  hh = 14.0;
  dd = 12.0;

  v = 0.0;
  a = -0.05;
}

void formatImage(BImage bi)
{
  // makes the image transparent + workaround for smoothing bug...

  bi.format = ALPHA;
  for (int i = 0; i < bi.width * bi.height; i++)
  {
    bi.pixels[i] = bi.pixels[i] & 0xff;
  }

  int tmp[] = new int[bi.pixels.length + bi.width * 2]; 
  System.arraycopy(bi.pixels, 0, tmp, 0, bi.pixels.length); 
  bi.pixels = tmp;
}

void loop()
{
  beginCamera();
  perspective(fovy, aspect, 1.0, 1000.0);
  translate(0.0, 0.0, -distance);
  rotateX(-elevation);
  rotateZ(-azimuth);
  endCamera();

  if (mousePressed)
  {
    collapse = true;
  }

  if (collapse)
  {
    v += a;
    h = max(15.0, h + v);
    if (h <= 15.0)
    {
      if (!exploded)
      {
        r2 = (r1 + r2) / 2.0;
        va = 0.0;
        exploded = true;
      }
      v = -v / 1.667;
    }
    aa = exploded ? 0.0 : radians(-0.0167);
  }

  turns = (img.width * hh / img.height) / (PI * (r1 + r2));

  drawTower(img, x, y, z, turns, r1, r2, h, hh, dd);

  va = max(0.0, va + aa);
  azimuth += va;
}

void drawTower(BImage bi, float x, float y, float z, float turns, float r1, float r2, float h, float hh, float dd)
{
  float d;
  float r = 0.0;
  float dr = 0.0;

  float l = TWO_PI * turns;
  float L = PI * turns * (r1 + r2);
  float dz = h / l;

  boolean conical = (abs(r1 - r2) > 0.5f);  // avoids infinity and divisions by zero with cylindrical helices (r1 = r2)
  if (conical)
  {
    dr = (r2 - r1) / l;
  }
  else
  {
    r = r1;
  }

  boolean b = false;
  float xx, yy, zz, uu;
  float du = bi.height / hh;

  noStroke();
  noSmooth();
  hint(SMOOTH_IMAGES);

  beginShape(QUAD_STRIP);
  textureImage(bi);
  for (float D = 0.0; D < L + dd; D += dd)
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

    b = !b;
    xx = x + cos(d) * r;
    yy = y - sin(d) * r;
    zz = z + d * dz;
    uu = D * du;

    fill(255, 255, 255, 153.0 + sin(PI + d + azimuth) * 102.0);  // depth effect...
    vertexTexture(uu, b ? (float) bi.height : 0.0);
    vertex(xx, yy, b ? zz : zz + hh); 
    vertexTexture(uu, b ? 0.0 : (float) bi.height);
    vertex(xx, yy, b ? zz + hh : zz); 
  }
  endShape();
}
