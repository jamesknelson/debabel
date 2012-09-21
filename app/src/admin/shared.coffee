{get, ready, view} = app = require './index'

pages = [
  {url: '/admin', title: 'Dashboard'}
  {highlight_url: /\/admin\/dictionary/, title: 'Dictionary', dropdown: [
	  {url: '/admin/dictionary', title: 'Browse'}
	  {modal_url: '/admin/dictionary/add', title: 'Add Word'}
  ]}
  {highlight_url: /\/admin\/sentences/, title: 'Sentences', dropdown: [
	  {url: '/admin/sentences', title: 'Browse'}
    {url: '/admin/sentences/polish', title: 'Polish Sentences'}
	  {modal_url: '/admin/sentences/add', title: 'Add Sentences'}
	  {modal_url: '/admin/sentences/import', title: 'Import Sentences'}
  ]}
]

exports.render = (namespace, page, ctx={}) -> 
  ctx.pages = pages
  ctx.activeUrl = page.params.url

  page.render namespace, ctx

#view.fn 'isDropDown', ->