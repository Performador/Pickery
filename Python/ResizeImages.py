from PIL import Image
import os
import glob

# Where the output will go
outFolder = '/tmp/PictoriaImages'
if os.path.exists(outFolder) == False:
	os.mkdir(outFolder)

def generateIcons():

	# The point sizes we will export
	sizes = [20, 29, 40, 60, 76, 83.5]

	iconFile = os.path.join(os.path.dirname(__file__),'../Designs/icon.png')

	for size in sizes:

		for retina in range(1,4):

			outName = 'Icon_{}'.format(size)
			if retina > 1:
				outName += '@' + str(retina) + 'x'
			outName += '.png'

			image =  Image.open(iconFile)
			image.thumbnail((size*retina,size*retina), Image.ANTIALIAS)
			image.convert('RGB').save(os.path.join(outFolder,outName))

def resizeBackgrounds():
	maxScale = int(3)

	for fileName in glob.glob(os.path.join(os.path.dirname(__file__),'../Designs/*.jpg')):
		
		# For each content scale, generate the output
		for contentScale in range(maxScale):
			scaleFactor = float(contentScale+1)/float(maxScale)
			image =  Image.open(fileName)
			image.thumbnail((image.size[0]*scaleFactor,image.size[1]*scaleFactor), Image.ANTIALIAS)
			outFileName = '{}@{}x.jpg'.format(os.path.basename(fileName).replace('.jpg',''),contentScale+1) if contentScale > 0 else os.path.basename(fileName)
			image.convert('RGB').save(os.path.join(outFolder,outFileName))	

		#print image.size
		#image.thumbnail((size*retina,size*retina), Image.ANTIALIAS)
		#image.convert('RGB').save(os.path.join('/tmp',outName))


generateIcons()

resizeBackgrounds()