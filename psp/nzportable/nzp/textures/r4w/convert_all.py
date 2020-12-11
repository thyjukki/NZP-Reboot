import os
import struct

def findall():
	filelist = os.listdir()
	#print(filelist)
	try:
		os.mkdir('out')
		print("Starting conversion, created 'out' directory...")
	except:
		print("Starting conversion, 'out' directory exists...")
		
	for filename in filelist:
		splits = filename.split('.')
		suffix = splits[-1]
		cancel = False
		if suffix is 'h':
			print("- Processing " + filename + "...")
			h = open(filename, 'r')
			width = -1
			height = -1
			
			for line in h:
				if line[0] is not '#':
					continue
				words = line.split()
				if words[1][-13:] == 'TEXTURE_WIDTH':
					width = int(words[2])
				elif words[1][-14:] == 'TEXTURE_HEIGHT':
					height = int(words[2])
				elif words[1][-14:] == 'TEXTURE_FORMAT':
					if words[2] != '4':
						print("-- Texture format not supported, only accepting GU_PSM_T4 !")
						cancel = True
				elif words[1][-15:] == 'TEXTURE_SWIZZLE':
					if words[2] != '1':
						print("-- Non-swizzled textures not recommended!")
						#cancel = True
				elif words[1][-14:] == 'PALETTE_FORMAT':
					if words[2] != '3':
						print("-- Palette format not supported, only accepting GU_PSM_8888 !")
						cancel = True
						
			if width == -1 or height == -1:
				print("Missing either width or height in header !")
				cancel = True
			
			newfile = open(filename[:-2] + '.r4w', 'wb')
			newfile.write(bytes("c4fe", 'utf-8'))
			newfile.write(struct.pack('i', width))
			newfile.write(struct.pack('i', height))
			newfile.write(bytes("xxxx", 'utf-8'))
			
			# the raw file
			try:
				raw = open(filename[:-2] + '.raw', 'rb')
				# (width * height / 2) bytes for 4bpp
				newfile.write(raw.read(int((width * height) / 2)))
				raw.close()
			except Exception as e:
				print('-- Couldn\'t read ' + filename[:-2] + '.raw')
				print("--- Exception: %s" % e)
				cancel = True
				
			# the rawpal file
			try:
				rawpal = open(filename[:-2] + '.rawpal', 'rb')
				# 4 bytes per color, 16 colors
				newfile.write(rawpal.read(4 * 16))
				rawpal.close()
			except Exception as e:
				print('-- Couldn\'t read ' + filename[:-2] + '.rawpal')
				print("--- Exception: %s" % e)
				cancel = True
			
			newfile.close()
			if cancel:
				os.remove(filename[:-2] + '.r4w')
				print('-- ' + filename[:-2] + '.r4w was NOT generated.')
			else:
				try:
					os.rename(filename[:-2] + '.r4w', 'out/' + filename[:-2] + '.r4w')
				except:
					os.remove('out/' + filename[:-2] + '.r4w')
					os.rename(filename[:-2] + '.r4w', 'out/' + filename[:-2] + '.r4w')
				print('-- Created ./out/' + filename[:-2] + '.r4w')
			
	
findall()