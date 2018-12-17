//more candidates for a smoother, less random image
int numCandidates = 20;
//when false, each pixel looks for the most similar color in RGB space to the ones near it
//else looks for the least similar color
boolean inverse = false;
//name of img to process, should be in images folder
String imgName = "shell.jpg";

/* everything above is a parameter */

PImage image;

//i = x j = y 
int i=0;
int j=0;

int numPixels;

//contains indexes of pixels
int[] candidates;

int currCandidates = 0;
boolean done = false;

void settings() {
  image = loadImage("images/"+imgName);
  if (image == null) {
    image = loadImage("localimages/"+imgName);
    if (image == null) {
      println("cannot find image, abort");
    }
  }
  size(image.width,image.height);
  numPixels = image.width*image.height;
}

void setup() {
  candidates = new int[numCandidates];
}

void draw() {
  if (i >= numPixels) {
    if (!done) {
      String savePrefix = (inverse)?"inverse_output_":"output_";
      save("output/"+savePrefix+imgName);
      done = true;
    }
    return;
  }
  background(100);
  //print(i + "\n");
  image(image,0,0);
  //set(i%image.width,i/image.width,color(0,0,0));
  image.loadPixels();
  
  processRow();
  i++;
  image.updatePixels();
}

void processRow() {
  int limit = image.width*(j+1);
  for(;i<limit;i++) {
    processPixel();
  }
  j++;
}

void processPixel() {
  for (int k=0;k<numCandidates;k++) {
    getRandomPixel();
  }
  //choice = index of closest color
  int choice = getClosestColor();
  int temp = image.pixels[i];
  image.pixels[i] = image.pixels[choice];
  image.pixels[choice] = temp;
  
  currCandidates=0;
}

int getColorFromArea(int index) {
  int r = 0;
  int g = 0;
  int b = 0;
  int numColors = 0;
  for (int x=-3; x<=-1;x++) {
    for (int y=-3; y<=-1;y++) {
      int pixelIndex = i+x+image.width*y;
      if (!isInImage(pixelIndex)) {
        continue;
      }
      int c = image.pixels[pixelIndex];
      r += red(c);
      g += green(c);
      b += blue(c);
      
      numColors++;
    }
  }
  if (numColors==0) {
    return image.pixels[i];
  }
  r /= numColors;
  g /= numColors;
  b /= numColors;
  
  return color(r,g,b);
}

int getClosestColor() {
  int closest=0;
  int sourceColor = getColorFromArea(i);
  //print(i+"\n");
  float closestColor = getColorDistance(sourceColor,image.pixels[candidates[0] ]);
  for (int k=1;k<numCandidates;k++) {
    float temp = getColorDistance(sourceColor,image.pixels[candidates[k] ]);
    if (inverse && (temp > closestColor) || !inverse && (temp < closestColor) ) {
      closest = k;
      closestColor = temp;
    }
  }
  return candidates[closest];
}
float getColorDistance(int a, int b) {
  //print("pixels a:" + a + " b: " + b + "\n");
  return abs(red(a)-red(b) ) + abs(green(a)-green(b) ) + abs(blue(a)-blue(b) );
}

void getRandomPixel() {
  //print("curr: " + currCandidates + "\n");
  int rand = i + floor(random(1)*(numPixels-i ) );
  candidates[currCandidates] = rand;
  currCandidates++;
}

boolean isInImage(int index) {
  return ! ( index < 0 || index >= numPixels );
}
