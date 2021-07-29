// HELIX TEXT 1
// by arielm, May 2003
// http://www.chronotext.org

// note: we are, for now, stuck on the y axis...

float fovy, aspect;
float elevation, azimuth, distance;

float x, y, z, turns, r1, r2, h;

BFont f;
float f_size;
color f_color;
String txt = "Sur le plancher, une araignee, se tricotait des bottes, dans un flacon, un limacon, enfilait sa culotte, j'ai vu dans le ciel, une mouche a miel, pincer sa guitare, des rats tous confus, sonner l'angelus, au son d'la fanfare";

float t;
boolean mumble;

void setup()
{
  size(300,300);
  framerate(20);
  //hint(SMOOTH_IMAGES);
  background(0);

  fovy = 60.0f;
  aspect = (float)width / (float)height;

  distance = 150.0f;
  elevation = radians(15.0f);
  azimuth = radians(-120.0f);

  x = 0.0f;
  y = 20.0f;
  z = 0.0f;
  turns = 3.0f;
  r1 = 75.0f;
  r2 = 25.0f;
  h = 100.0f;

  f = loadFont("Univers65.vlw.gz");  // don't forget to have this font included in your "data" folder...
  f_size = 10.0f;
  f_color = color(255, 255, 255);

  t = radians(90.0f);
  mumble = false;
}

void mousePressed()
{
  mumble = !mumble;
}

void loop()
{
  beginCamera();
  perspective(fovy, aspect, 1.0f, 1000.0f);
  translate(0.0f, 0.0f, -distance);
  rotateX(-elevation);
  rotateY(-azimuth);
  endCamera();

  drawHelixText(x, y, z, turns, r1, r2, h, f, f_size, f_color, txt);

  azimuth += radians(1.0f);

  if (mumble)
  {
    r2 = 50.0f - 25.0f * sin(t);
    r1 = 50.0f + 25.0f * sin(t);
    h = 75.0f + 25.0f * sin(t);
    t += radians(2.0f);
  }
}

void drawHelixText(float x, float y, float z, float turns, float r1, float r2, float h, BFont font, float font_size, color font_color, String s)
{
  float c = TWO_PI * turns;
  float dr = (r2 - r1) / c;
  float dy = -h / c;

  float r = r1;
  float d = 0.0f;

  int index = s.length();
  char ch;

  font.setSize(font_size);
  colorMode(RGB, 255, 255, 255, 1);
  float rouge = red(font_color);
  float vert = green(font_color);
  float bleu = blue(font_color);

  while(index > 0)
  {
    ch = s.charAt(--index);
    d += font.charWidth(ch) / r;
    if (d >= c)
    {
      break;
    }
    r = r1 + d * dr;
    
    fill(rouge, vert, bleu, 0.6 + 0.4 * cos(azimuth + d));  // simple depth effect...
    push();
    translate(x - sin(d) * r, y + d * dy, z + cos(d) * r);
    rotateY(-d);
    rotateZ(atan2(h , c * r));  // banking...
    font.drawChar(ch, 0.0f, 0.0f);
    pop();
  }
}
