import {EditorState,basicSetup} from "@codemirror/basic-setup"
import {javascript} from "@codemirror/lang-javascript"

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


      // Fires when an instance of the element is created
      constructor(self) {

        console.log("EDITOR: In constructor")

        self = super(self)

        return self
    }

    connectedCallback() {

        console.log("EDITOR: In connectedCallback")

        let editor = new EditorView({
            state: EditorState.create({
              extensions: [basicSetup
                , fixedHeightEditor
                , myTheme
                , EditorView.lineWrapping
                , EditorView.updateListener.of((v)=> {
                    if(v.docChanged) {
                        console.log( editor.state.doc.toString());
                    }
                  })
                ],
            doc: "L0 is simple markup language whose syntax is inspired by Lisp. L0 text consists of ordinary text, elements, and blocks.  L0 is simple markup language whose syntax is inspired by Lisp. L0 text consists of ordinary text, elements, and blocks.  L0 is simple markup language whose syntax is inspired by Lisp. L0 text consists of ordinary text, elements, and blocks.  L0 is simple markup language whose syntax is inspired by Lisp. L0 text consists of ordinary text, elements, and blocks."

            }),
            parent: document.getElementById("editor-here")

          })

    }

  }

customElements.define("codemirror-editor", CodemirrorEditor); // (2)


// const currentValue = editor.state.doc.toString();


