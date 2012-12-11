
gecko = /gecko\/\d/i.test(navigator.userAgent)
ie = /MSIE \d/.test(navigator.userAgent)
ie_lt8 = /MSIE [1-7]\b/.test(navigator.userAgent)
ie_lt9 = /MSIE [1-8]\b/.test(navigator.userAgent)
webkit = /WebKit\//.test(navigator.userAgent)
qtwebkit = webkit and /Qt\/\d+\.\d+/.test(navigator.userAgent)
chrome = /Chrome\//.test(navigator.userAgent)
opera = /Opera\//.test(navigator.userAgent)
safari = /Apple Computer/.test(navigator.vendor)
khtml = /KHTML\//.test(navigator.userAgent)
mac_geLion = /Mac OS X 1\d\D([7-9]|\d\d)\D/.test(navigator.userAgent)
mac_geMountainLion = /Mac OS X 1\d\D([8-9]|\d\d)\D/.test(navigator.userAgent)
phantom = /PhantomJS/.test(navigator.userAgent)
ios = /AppleWebKit/.test(navigator.userAgent) and /Mobile\/\w+/.test(navigator.userAgent)
mac = ios or /Mac/.test(navigator.platform)

t = -> a: 1, b: 2

return false if typeof command == "string" and !(command = commands[command])
	