#!/usr/bin/env python

import cairo
import os
import subprocess

class VarDDT:

	def __init__(self):

		self.FILE = 'tmp.pdf'
		self.VIEWER = '/usr/bin/evince'

		self.WIDTH = 744.09
		self.HEIGHT = 1052.36

		self.FONT_SIZE = 40
		self.LINE_WIDTH = 1

		self.CELL_PADDING_X = self.FONT_SIZE / 4
		self.CELL_PADDING_Y = self.FONT_SIZE / 4


	def prepare(self):

		self.surface = cairo.PDFSurface(self.FILE, self.WIDTH, self.HEIGHT)
		self.cr = cairo.Context(self.surface)

		self.cr.set_source_rgb(0, 0, 0)
		self.cr.set_font_size(self.FONT_SIZE)
		self.cr.set_line_width(self.LINE_WIDTH)


	def finish(self):

		self.cr.show_page()
		self.surface.finish()


	def paint(self):
		"""Paint some stuff."""

		# Leave a 10px margin around the table
		x = 10
		y = 10
		width = self.WIDTH - (2 * x)

		y += self._paint_cell(x, y, width, 0, "This text goes into a cell")
		y += self._paint_cell(x, y, width, 0, "This other text is a little too long to fit in a single line")


	def show(self):

		subprocess.call([self.VIEWER, self.FILE])
		os.unlink(self.FILE)


	def run(self):
		"""Prepare and show a DDT."""

		self.prepare()
		self.paint()
		self.finish()
		self.show()


	def _split_text(self, text, width):
		"""Split the text so that it fits the given width.

		Parameters:
		text -- text to draw
		width -- horizontal space available

		Returns:
		a list of strings fitting the given width

		"""

		lines = []
		start = 0
		last = 0

		for i in xrange(0, len(text)):

			# Get the size of the part of text from the last cut to here
			xt = self.cr.text_extents(text[start:i])

			# We're beyond the allowed width: cut the text
			if xt[2] > width:
				lines.append(text[start:last])
				start = last + 1
				last = start

			# Mark the last seen space
			if text[i] == ' ':
				last = i

		# Add also the last chunk
		lines.append(text[start:len(text)])

		return lines


	def _paint_cell(self, x, y, width, height, text):
		"""Draw a cell containing some text.

		Parameters:
		x -- cell horizontal starting point
		y -- cell vertical starting point
		width -- width of the cell
		height -- ignored. The cell height is calculated on the fly
		text -- text to draw inside the cell

		Returns:
		cell height

		"""

		# Use a test string to find the right cell height
		xt = self.cr.text_extents('Pp')
		adjustment_x = xt[0]
		adjustment_y = xt[1]

		lines = self._split_text(text, width - (2 * self.CELL_PADDING_X))

		cell_height = xt[3] + (2 * self.CELL_PADDING_Y)

		text_x = x + self.CELL_PADDING_X - adjustment_x
		text_y = y + self.CELL_PADDING_Y - adjustment_y

		self.cr.rectangle(x, y, width, cell_height)
		self.cr.stroke()

		self.cr.move_to(text_x, text_y)
		self.cr.show_text(lines[0])

		return cell_height


if __name__ == '__main__':

	VarDDT().run()
