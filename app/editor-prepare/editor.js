import {EditorState,basicSetup} from "@codemirror/basic-setup"
// import {javascript} from "@codemirror/lang-javascript"

import {EditorView} from "@codemirror/view"

const fixedHeightEditor = EditorView.theme({
    "&": {height: "800px"},
    ".cm-scroller": {overflow: "auto"}
  })

let myTheme = EditorView.theme({

  ".cm-content": {
    caretColor: "#0e9"
  },
  "&.cm-focused .cm-cursor": {
    borderLeftColor: "#0e9"
  },
  "&.cm-focused .cm-selectionBackground, ::selection": {
    backgroundColor: "#074"
  },
  ".cm-gutters": {
    backgroundColor: "#045",
    color: "#ddd",
    border: "none"
  }

}, {dark: true})




class CodemirrorEditor extends HTMLElement { // (1)

    get editorText() {
            //return the editor text
            console.log("Called: editorText()")
            return this.editor.state.doc.toString()
        }

    constructor(self) {

        self = super(self)
        console.log("CM EDITOR: In constructor")

        return self
    }


    connectedCallback() {


        console.log("CM EDITOR: In connectedCallback")

            function sendText(editor) {
                const event = new CustomEvent('text-change', { 'detail': editor.state.doc.toString() , 'bubbles':true, 'composed': true});
                editor.dom.dispatchEvent(event);
             }


        let editor = new EditorView({
            state: EditorState.create({
              extensions: [basicSetup
                , fixedHeightEditor
                , myTheme
                // , EditorView.updateListener.of(update => console.log( "HOLA:" + editor.state.doc.toString()))
                , EditorView.lineWrapping
                , EditorView.updateListener.of((v)=> {
                    if(v.docChanged) {
                        sendText(editor)
                    }
                  })
                ],
            doc: "L0 is simple markup language whose syntax is inspired by Lisp."

            }),
            parent: document.getElementById("editor-here")

          })

//          editor.on("change", (event) => {
//                          element.dispatchEvent(new CustomEvent("change", { bubbles: true, composed: true, detail: event }))
//                      })

    }

  }

customElements.define("codemirror-editor", CodemirrorEditor); // (2)


// const currentValue = editor.state.doc.toString();


