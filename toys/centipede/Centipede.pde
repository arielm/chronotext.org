// CENTIPEDE
// by ariel malka, march 2004
// http://www.chronotext.org

Worm centipede;

void setup()
{
  size(384, 384);

  centipede = new Worm(width / 2, height / 2, 10, 100, 4, 100, 7, 5, color(255, 0, 0), color(255, 255, 255));
}

void loop()
{
  background(0);
  
  if (mousePressed)
  {
    centipede.setTarget(mouseX, mouseY);
  }

  centipede.draw();
}

class Worm
{
  float x, y;
  int n_nodes;
  float node_length;
  float[] nodes_x;
  float[] nodes_y;
  float delay;
  int col_head, col_body;

  Worm(float x, float y, float r1, float r2, float turns, int n_nodes, float node_length, float delay, int col_head, int col_body)
  {
    // n_nodes must be > 1
    // delay must be > 1.0

    float l = TWO_PI * turns;
    float L = PI * turns * (r1 + r2);
    float dr = (r2 - r1) / l;
    float r, d;
    float D = 0;

    this.x = x;
    this.y = y;
    this.n_nodes = max(1, n_nodes);
    this.node_length = node_length;
    this.delay = max(1, delay);
    this.col_head = col_head;
    this.col_body = col_body;

    nodes_x = new float[n_nodes];
    nodes_y = new float[n_nodes];
    for (int i = 0; i < n_nodes; i++)
    {
      r = sqrt(r1 * r1 + 2f * dr * D);
      d = (r - r1) / dr;

      nodes_x[i] = x - sin(d) * r;
      nodes_y[i] = y + cos(d) * r;

      D += node_length;
    }
  }

  void setTarget(float tx, float ty)
  {
    // motion interpolation for the head
    x += (tx - x) / delay;
    y += (ty - y) / delay;
    nodes_x[0] = x;
    nodes_y[0] = y;

    // constrained motion for the other nodes
    float dx, dy, len;
    for (int i = 1; i < n_nodes; i++)
    {
      dx = nodes_x[i - 1] - nodes_x[i];
      dy = nodes_y[i - 1] - nodes_y[i];
      len = sqrt(dx * dx + dy * dy);
      nodes_x[i] = nodes_x[i - 1] - dx / len * node_length;
      nodes_y[i] = nodes_y[i - 1] - dy / len * node_length;
    }
  }

  void draw()
  {
    ellipseMode(CENTER_RADIUS);
    noStroke();

    fill(col_head);
    ellipse(nodes_x[0], nodes_y[0], 2, 2);

    fill(col_body);
    for (int i = 1; i < n_nodes; i++)
    {
      ellipse(nodes_x[i], nodes_y[i], 2, 2);
    }
  }
}
