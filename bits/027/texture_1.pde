// TEXTURE 1
// by arielm - May 30, 2003
// http://www.chronotext.org

float fovy, aspect;
float elevation, azimuth, distance;

BImage img;

void setup()
{
  size(300, 300);
  framerate(20.0);
  background(0);
  //hint(SMOOTH_IMAGES);  // !!! crashes under 0054 !!!

  fovy = 60.0;
  aspect = (float) width / (float) height;

  distance = 200.0;
  elevation = radians(285.0);
  azimuth = radians(235.0);

  img = loadImage("img.gif");
  formatImage(img);
}

void formatImage(BImage bi)
{
  bi.format = ALPHA;
  for (int i = 0; i < bi.width * bi.height; i++)
  {
    bi.pixels[i] = bi.pixels[i] & 0xff;
  }
}

void loop()
{
  beginCamera();
  perspective(fovy, aspect, 1.0, 1000.0);
  translate(0.0, 0.0, -distance);
  rotateX(-elevation);
  rotateZ(-azimuth);
  endCamera();

  noStroke();

  fill(224, 224 ,255);
  drawBadShape(img, 0.0, 0.0, -40.0, 90.0, 16.0, radians(12.0));

  fill(255);
  drawBadShape(img, 0.0, 0.0, -20.0, 120.0, 16.0, radians(12.0));

  azimuth += radians(1.0);
}

void drawBadShape(BImage bi, float x, float y, float z, float r, float h, float dd)
{
  boolean b = false;
  float xx, yy, uu;

  beginShape(QUAD_STRIP);
  textureImage(bi);
  for (float d = 0.0; d < TWO_PI * 2.0; d += dd)
  {
    b = !b;
    xx = x + cos(d) * r;
    yy = y - sin(d) * r;
    uu = d * r * bi.height / h;
    vertexTexture(uu, b ? (float) bi.height : 0.0); vertex(xx, yy, b ? z : z + h); 
    vertexTexture(uu, b ? 0.0 : (float) bi.height); vertex(xx, yy, b ? z + h : z); 

    z += 1.0;
  }
  endShape();
}
