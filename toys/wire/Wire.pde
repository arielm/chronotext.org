// WIRE
// by ariel malka, march 2004
// http://www.chronotext.org

float dt = 1 / 3f; // affects the overall speed of the physics...
float friction = 0.75f; // between 0 and 1

Worm2 wire;

void setup()
{
  size(384, 384);

  wire = new Worm2(400, 4); // a 1600 pixel-long wire...
}

void loop()
{
  background(0);
  wire.run();
}

class Worm2
{
  int NUM_ITERATIONS = 200; // play with that param!

  int n_nodes;
  float D, D2;
  float[] nodes_x;
  float[] nodes_y;

  float[] old_x;
  float[] old_y;

  boolean armed = false;
  int selected = -1;

  Worm2(int n_nodes, float D)
  {
    this.n_nodes = max(1, n_nodes);
    this.D = D;
    D2 = D * D;

    nodes_x = new float[n_nodes];
    nodes_y = new float[n_nodes];

    old_x = new float[n_nodes];
    old_y = new float[n_nodes];
    for (int i = 0; i < n_nodes; i++)
    {
      nodes_x[i] = old_x[i] = random(0, width);
      nodes_y[i] = old_y[i] = random(0, height);
    }
  }

  void run()
  {
    mouseOver();

    verlet();
    satisfyConstraints();

    draw();
  }

  void verlet() // a special version of the classic Verlet integration, that doesn't take care of external forces, but that includes friction...
  {
    float f = (1 - friction * dt * dt); // precalculated pal!

    float tmp_x, tmp_y;
    for (int i = 0; i < n_nodes; i++)
    {
      tmp_x = nodes_x[i];
      tmp_y = nodes_y[i];

      nodes_x[i] += (nodes_x[i] - old_x[i]) * f;
      nodes_y[i] += (nodes_y[i] - old_y[i]) * f;

      old_x[i] = tmp_x;
      old_y[i] = tmp_y;
    }
  }

  void satisfyConstraints()
  {
    if (selected != -1)
    {
      nodes_x[selected] = mouseX;
      nodes_y[selected] = mouseY;
    }

    float dx, dy, diff, len;
    for (int j = 0; j < NUM_ITERATIONS; j++)
    {
      for (int i = 0; i < n_nodes - 1; i++)
      {
        dx = nodes_x[i + 1] - nodes_x[i];
        dy = nodes_y[i + 1] - nodes_y[i];
        len = sqrt(dx * dx + dy * dy);
        diff = (len - D) / len;
        dx *= 0.5 * diff;
        dy *= 0.5 * diff;

        nodes_x[i] += dx;
        nodes_y[i] += dy;
        nodes_x[i + 1] -= dx;
        nodes_y[i + 1] -= dy;
      }
    }
  }

  void draw()
  {
    stroke(255);
    for (int i = 0; i < n_nodes - 1; i++)
    {
      line(nodes_x[i], nodes_y[i], nodes_x[i + 1], nodes_y[i + 1]);
    }

    if (selected != -1)
    {
      drawRollOver(selected);
    }
  }

  void drawRollOver(int n)
  {
    ellipseMode(CENTER_RADIUS);
    noFill();
    stroke(255, 0, 0);
    ellipse(nodes_x[n], nodes_y[n], 4, 4);
  }

  void mouseOver()
  {
    if (!mousePressed)
    {
      armed = false;
      selected = -1;
    }

    if (!armed)
    {
      for (int i = 0; i < n_nodes; i++)
      {
        if (mouseX >= nodes_x[i] - 2 && mouseX <= nodes_x[i] + 2 && mouseY >= nodes_y[i] - 2 && mouseY <= nodes_y[i] + 2)
        {
          if (mousePressed)
          {
            armed = true;
            selected = i;
          }
          drawRollOver(i);
          break;
        }
      }
    }
  }
}
