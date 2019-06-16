import gifAnimation.*;

//more candidates for a smoother, less random image
int numCandidates = 200;
//when false, each pixel looks for the most similar color in RGB space to the ones near it
//else looks for the least similar color
boolean inverse = true;
//uses gifAnimation to record a gif from frames, is extremely slow atm
//Currently will not make gifs over roughly 1MB
boolean recordGIF = false;
//the image impression stuff superimposes an image over the final piece by affecting
//the number of candidate pixels processpixel picks.
//Darker the pixel of impression image -> less candidates -> fuzzier section
//if true, uses impression image to create distortion in the output
boolean imageImpression = false;
String impressionName = "Daddoe.png";
float impressionStrength = .3f;
//offset for impression image
int impOffsetX = 0;
int impOffsetY = 0;
//
int colorAreaSize = 10;
//name of img to process, should be in images folder
String imgName = "random.JPG";

/* everything above is a parameter */

PImage image;

PImage impImage;

//i = x j = y 
int i=0;
int j=0;

int numPixels;

//contains indexes of pixels
int[] candidates;

int currCandidates = 0;
boolean done = false;

//gif stuff
GifMaker gifExport;
int frames = 0;

void settings() {
  image = loadImage("images/"+imgName);
  if (image == null) {
    image = loadImage("localimages/"+imgName);
    if (image == null) {
      println("cannot find image, abort");
    }
  }
  if (imageImpression) {
    impImage = loadImage("images/"+impressionName);
    if (impImage == null) {
      impImage = loadImage("localimages/"+impressionName);
      if (impImage == null) {
        println("cannot find impression image, abort");
      }
    }
  }
  size(image.width,image.height);
  numPixels = image.width*image.height;
}

void setup() {
  candidates = new int[numCandidates];
  String sanitizedName = "export";
  for (int a=0;a<imgName.length();a++) {
    if (imgName.charAt(a) == '.') {
      sanitizedName = imgName.substring(0,a);
    }
  }
  gifExport = new GifMaker(this, "gifs/"+sanitizedName+".gif", 100);
  gifExport.setRepeat(0); // make it an "endless" animation
}

void draw() {
  if (i >= numPixels) {
    if (!done) {
      String savePrefix = (inverse)?"inverse_output_":"output_";
      save("output/"+savePrefix+imgName);
      done = true;
      if (recordGIF) {
        export();
        finishexport();
      }
    }
    return;
  }
  background(100);
  image(image,0,0);
  //set(i%image.width,i/image.width,color(0,0,0));
  image.loadPixels();
  if (imageImpression) {
    impImage.loadPixels();
  }
  
  processRow();
  i++;
  image.updatePixels();
  export();
}

void processRow() {
  int limit = image.width*(j+1);
  for(;i<limit;i++) {
    processPixel();
  }
  j++;
}

float isImpression() {
  if (!imageImpression) {
    return -1;
  }
  int x = i%width;
  if (x < impOffsetX || x >= impOffsetX + impImage.width) {
    return -1;
  }
  int y = i/width;
  if (y < impOffsetY || y >= impOffsetY + impImage.height) {
    return -1;
  }
  int newI = impImage.pixels[(x-impOffsetX + (y-impOffsetY) * impImage.width)];
  if (alpha(newI) != 0) {
    return  impressionStrength * pow((255 - (red(newI)*0.2989f+ green(newI)*0.5870f+blue(newI)* 0.1140f) )/255,1);
  }
  return -1;
}

void processPixel() {
  float impVal = isImpression();
  if (imageImpression && impVal != -1 ) {
    for (int k=0;k<numCandidates/((numCandidates*.8)*impVal+1);k++) {
      getRandomPixel();
    }
    //image.pixels[i] = color(impVal*255);
    //return;
  } else {
    for (int k=0;k<numCandidates;k++) {
      getRandomPixel();
    }
  }
  
  //choice = index of closest color
  int choice = getClosestColor();
  int temp = image.pixels[i];
  image.pixels[i] = image.pixels[choice];
  image.pixels[choice] = temp;
  
  if (impVal > 0) {
    float darkCoeff = .95f;
    image.pixels[i] = color(darkCoeff*red(image.pixels[i]),darkCoeff*green(image.pixels[i]),darkCoeff*blue(image.pixels[i]));
  }
  
  currCandidates=0;
}

int getColorFromArea(int index) {
  int r = 0;
  int g = 0;
  int b = 0;
  int numColors = 0;  for (int x=-colorAreaSize; x<=-1;x++) {
    for (int y=-colorAreaSize; y<=-1;y++) {
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
  for (int k=1;k<currCandidates;k++) {
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
  
  return pow(pow(red(a)-red(b),2)+pow(green(a)-green(b),2)+pow(blue(a)-blue(b),2),.5f);
  
  //abs(red(a)-red(b) ) + abs(green(a)-green(b) ) + abs(blue(a)-blue(b) );
  
  //return abs(red(a)-red(b) ) + abs(green(a)-green(b) ) + abs(blue(a)-blue(b) );
}

void getRandomPixel() {
  int rand = i + floor(random(1)*(numPixels-i ) );
  candidates[currCandidates] = rand;
  currCandidates++;
}

boolean isInImage(int index) {
  return ! ( index < 0 || index >= numPixels );
}

void export() {
  if (!recordGIF) {
    return;
  }
  gifExport.setDelay(20);
  gifExport.addFrame();
}
void finishexport() {
  if (!recordGIF) {
    return;
  }
  gifExport.finish();
  println("gif saved");
  exit();
}
