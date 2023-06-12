monitor = peripheral.wrap("left")
sensor = peripheral.wrap("right")

monitor.setScale(0.5)
term.redirect(monitor)

width, height = term.getSize()
