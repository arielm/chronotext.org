// HELIX TEXT 2
// by arielm, May 2003
// http://www.chronotext.org

float fovy, aspect;
float elevation, azimuth, distance;

float x, y, z, turns, r1, r2, h, o;

BFont f;
float f_size;
color f_color;
String txt = "Sur le plancher, une araignee, se tricotait des bottes, dans un flacon, un limacon, enfilait sa culotte, j'ai vu dans le ciel, une mouche a miel, pincer sa guitare, des rats tous confus, sonner l'angelus, au son d'la fanfare";

float t;
boolean mumble;

void setup()
{
  size(300, 300);
  framerate(20);
  //hint(SMOOTH_IMAGES);
  background(255);

  fovy = 60.0f;
  aspect = (float)width / (float)height;

  distance = 142.0f;
  elevation = radians(15.0f);
  azimuth = radians(0.0f);

  f = loadFont("Univers65.vlw.gz");  // don't forget to have this font included in your "data" folder...
  f_size = 10.0f;
  f_color = color(0, 0, 0);

  x = 0.0f;
  y = 30.0f;
  z = 0.0f;
  r1 = 0.0f;
  r2 = 64.0f;
  h = 80.0f;

  f.setSize(f_size);
  turns = (f.stringWidth(txt) + 0.5f) / (PI * (r1 + r2));  // stringWidth() won't be accurate when kerning is implemented in P5!..

  t = radians(90.0f);
  mumble = true;
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
    r1 = 32.0f - 32.0f * sin(t);
    r2 = 32.0f + 32.0f * sin(t);
    t += radians(2.0f);
  }
}

void drawHelixText(float x, float y, float z, float turns, float r1, float r2, float h, BFont font, float font_size, color font_color, String s)
{
  float d;
  float D = 0.0;
  float r = 0.0;
  float dr = 0.0;

  float l = TWO_PI * turns;
  float L = PI * turns * (r1 + r2);
  float dy = -h / l;

  boolean conical = (abs(r1 - r2) > 0.5f);  // avoids infinity and divisions by zero with cylindrical helices (r1 = r2)
  if (conical)
  {
    dr = (r2 - r1) / l;
  }
  else
  {
    r = r1;
  }

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
    D += font.charWidth(ch);

    if (D >= L)
    {
      break;
    }

    if (conical)
    {
      r = sqrt(r1 * r1 + 2.0f * dr * D);
      d = (r - r1) / dr;
    }
    else
    {
      d = D / r;
    }
    
    fill(rouge, vert, bleu, 0.6f + 0.4f * cos(azimuth + d));  // simple depth effect...
    push();
    translate(x - sin(d) * r, y + d * dy, z + cos(d) * r);
    rotateY(-d);
    rotateZ(atan2(h , l * r));  // banking...
    font.drawChar(ch, 0.0f, 0.0f);
    pop();
  }
}
