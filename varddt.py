#!/usr/bin/env python
# vim: set fileencoding=utf-8 :

import cairo
import rsvg
import os
import subprocess

class VarDDT:

	def __init__(self):

		self.FILE = 'tmp.pdf'
		self.VIEWER = '/usr/bin/evince'

		self.TEMPLATE = 'template.svg'

		self.WIDTH = 744.09
		self.HEIGHT = 1052.36

		self.FONT_SIZE = 10
		self.LINE_WIDTH = 1

		self.CELL_PADDING_X = self.FONT_SIZE / 2
		self.CELL_PADDING_Y = self.FONT_SIZE / 2


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

		# Render template
		template = rsvg.Handle(self.TEMPLATE)
		template.render_cairo(self.cr)

		# Render a table with sample data
		x = 10
		y = 100
		long_text = 'This is a very long text used to test the text wrapping capabilities of this nice piece of code I\'m writing '
		widths = [100, 50, self.WIDTH - 320, 50, 100]
		contents = [["ONE", "1337", "9"], ["TWO", "02/b", "62"], ["THREE", long_text, "Some cool things"], ["FOUR", "???", "?"], ["FIVE", "9001", "3"]]

		self._paint_table(x, y, widths, contents)


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


	def _paint_table(self, x, y, widths, contents):
		"""Draw a table.

		Parameters:
		x -- table horizontal starting point
		y -- table vertical starting point
		widths -- list of columns widths
		contents -- list of columns contents

		"""

		if len(contents) < 1 or len(contents) != len(widths):
			return

		cell_x = x
		cell_y = y

		# Calculate the number of rows and columns
		columns = len(widths)
		rows = len(contents[0])
		for i in xrange(0, columns):
			rows = min(rows, len(contents[i]))

		# Draw one row at a time
		for i in xrange(0, rows):

			cell_x = x
			row_height = 0

			# Paint one cell at a time
			for j in xrange(0, columns):

				# Paint the contents of the cell
				height = self._paint_cell(cell_x, cell_y, widths[j], 0, contents[j][i])

				# Move to the next column
				cell_x += widths[j]
				row_height = max(height, row_height)

			cell_x = x

			# Paint all the cell borders
			for j in xrange(0, columns):

				self.cr.rectangle(cell_x, cell_y, widths[j], row_height)
				self.cr.stroke()

				cell_x += widths[j]

			cell_y += row_height


	def _paint_cell(self, x, y, width, height, text):
		"""Draw some text so that it fits a cell.

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
		line_height = xt[3]

		lines = self._split_text(text, width - (2 * self.CELL_PADDING_X))

		text_x = x + self.CELL_PADDING_X - adjustment_x
		text_y = y + self.CELL_PADDING_Y - adjustment_y

		for line in lines:
			self.cr.move_to(text_x, text_y)
			self.cr.show_text(line)
			text_y += line_height + self.CELL_PADDING_Y

		cell_height = len(lines) * line_height
		cell_height += (len(lines) + 1) * self.CELL_PADDING_Y

		return cell_height


if __name__ == '__main__':

	VarDDT().run()
