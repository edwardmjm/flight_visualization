import java.util.*;

int n;
float dotSize, dotMax, dotMin, dotChange;
float[] airportLon;
float[] airportLat;
float[] airportX;
float[] airportY;
float lonHi, lonLo;
float latHi, latLo;
float [][]graph;
int []graphU;
int []graphV;
float maxGraphElement = 0;
float rotAngle = HALF_PI; //+ PI;
HashMap <String, Integer> indexOfCity = new HashMap <String, Integer> ();


void initAirPorts() {
  String dataLines[] = loadStrings("airports.csv");
  n = dataLines.length - 1;
  airportLon = new float [n];
  airportLat = new float [n];
  airportX = new float[n];
  airportY = new float[n];
  for (int counter = 0; counter < n; counter++) {
    String[] temp = split(dataLines[counter + 1], ',');
    indexOfCity.put(temp[0], counter);
    airportLat[counter]=float(temp[5]);
    airportLon[counter]=float(temp[6]);
    airportX[counter] = map(airportLon[counter], -170, 0, 150, width+300);
    airportY[counter] = map(airportLat[counter], 10, 80, height-100, 0);
  }
}

void buildGraph() {
  graph = new float [n][n];
  for (int i = 0; i < n; i++)
    for (int j = 0; j < n; j++)
      graph[i][j] = 0;
  String data[] = loadStrings("airline.txt");
  int m = data.length, cnt = 0;
  for (int i = 0; i < m; i++) {
    String[] tmp = split(data[i], ',');
    Integer u = indexOfCity.get(tmp[0]);
    Integer v = indexOfCity.get(tmp[1]);
    if (u != null && v != null) {
      cnt++;
      graph[u][v] += float(tmp[2]);
    }
  }
  graphU = new int[cnt];
  graphV = new int[cnt];
  cnt = 0;
  float minv = 1e20f;
  float maxv = -1e20f;
  for (int i = 0; i < m; i++) {
    String[] tmp = split(data[i], ',');
    Integer u = indexOfCity.get(tmp[0]);
    Integer v = indexOfCity.get(tmp[1]);
    if (u != null && v != null) {
      if (graph[u][v] < minv) minv = graph[u][v];
      if (graph[u][v] > maxv) maxv = graph[u][v];
      graphU[cnt] = u;
      graphV[cnt] = v;
      cnt++;
    }
  }
  for (int i = 0; i < cnt; i++) {
    for (int j = i + 1; j < cnt; j++) {
      if (graph[graphU[i]][graphV[i]] > graph[graphU[j]][graphV[j]]) {
        int tmp = graphU[i]; graphU[i] = graphU[j]; graphU[j] = tmp;
        tmp = graphV[i]; graphV[i] = graphV[j]; graphV[j] = tmp;
      }
    }
  }
  maxGraphElement = cnt;
  println(maxv + ", " + minv);
}

void setup() {
  size (960,800);
  //size(1960, 1080);
  smooth();
  noStroke();
  initAirPorts();
  buildGraph();
  dotSize=5;
  dotMax=3;
  dotMin=1;
  dotChange=0.5;
  println(graphU.length);
  noLoop();
}

float changeV(float v) {
  float res = v / maxGraphElement * 255.0;
  return res < 40 ? 40 : res;
}
 
void draw() {
  smooth();
  noStroke();
  background(0);
  fill(#F9FCAB);
  for (int i = 0; i < n; i++) { 
    ellipse (airportX[i], airportY[i], dotSize, dotSize);
  }
  int u, v;
  float tmp, x0, x1, y0, y1, d, mx, my, R, G, B, V, U, Y;
  PVector vec = new PVector(0, 0);
  //colorMode(HSB, maxGraphElement * 2);
  noFill();
  for (int i = 0; i < graphU.length; i++) {
    u = graphU[i];
    v = graphV[i];
    x0 = airportX[u];
    y0 = airportY[u];
    x1 = airportX[v];
    y1 = airportY[v];
    if (x0 > x1) {
      tmp = x0; x0 = x1; x1 = tmp;
      tmp = y0; y0 = y1; y1 = tmp;
    }
    mx = (x0 + x1) / 2.0;
    my = (y0 + y1) / 2.0;
    vec.set(x1 - x0, y1 - y0);
    vec.rotate(rotAngle);
    vec.mult(2);
    mx += vec.x;
    my += vec.y;
    d = dist(x0, y0, mx, my);
    Y = changeV(i);
    U = V = 0;
    R = Y + 1.14 * V;
    G = Y - 0.39 * U - 0.58 * V;
    B = Y + 2.03 * U;
    stroke(R, G, B);
    arc(mx, my, d * 2, d * 2, (new PVector(x0 - mx, y0 - my)).heading(), (new PVector(x1 - mx, y1 - my)).heading());
  }
  doPulse();
}
 
void doPulse() {
  //dotSize=dotSize+dotChange;
  if (dotSize>dotMax || dotSize<dotMin) {
    dotChange=dotChange*-1.0;
  }
}




