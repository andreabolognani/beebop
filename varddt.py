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

		self.PADDING_X = self.FONT_SIZE / 4
		self.PADDING_Y = self.FONT_SIZE / 4


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

		self._boxed_text(10, 10, "omg!!1")
		self._boxed_text(200, 10, "In a box")
		self._boxed_text(400, 10, "So very pretty")


	def show(self):

		subprocess.call([self.VIEWER, self.FILE])
		os.unlink(self.FILE)


	def run(self):

		self.prepare()
		self.paint()
		self.finish()
		self.show()


	def _boxed_text(self, x, y, text):

		xt = self.cr.text_extents('Pp')
		adjustment_x = xt[0]
		adjustment_y = xt[1]
		line_height = xt[3]

		xt = self.cr.text_extents(text)
		line_length = xt[2]

		text_x = x + self.PADDING_X - adjustment_x
		text_y = y + self.PADDING_Y - adjustment_y

		self.cr.rectangle(x, y, line_length + 2 * self.PADDING_X, line_height + 2 * self.PADDING_Y)
		self.cr.stroke()

		self.cr.move_to(text_x, text_y)
		self.cr.show_text(text)


if __name__ == '__main__':

	VarDDT().run()
