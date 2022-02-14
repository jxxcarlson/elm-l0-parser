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




class CodemirrorEditor extends HTMLElement {

    static get observedAttributes() { return ['yada', 'text']; }



    constructor(self) {

        self = super(self)
        console.log("CM EDITOR: In constructor")
//



        return self
    }

    connectedCallback() {

        console.log("CM EDITOR: In connectedCallback")

            function sendText(editor) {
                const event = new CustomEvent('text-change', { 'detail': editor.state.doc.toString() , 'bubbles':true, 'composed': true});
                editor.dom.dispatchEvent(event);
             }

         if (this.editor) {
                    editor = this.editor
                } else {
                    const options = {}
                    // Support autoresizing
//                    if (this.hasAttribute("max-lines")) {
//                        options.maxLines = Number(this.getAttribute("max-lines"))
//                    }
//                    if (this.hasAttribute("min-lines")) {
//                        options.minLines = Number(this.getAttribute("min-lines"))
//                    }

                    let editor = new EditorView({
                               state: EditorState.create({
                                 extensions: [basicSetup
                                   , fixedHeightEditor
                                   , myTheme
                                   , EditorView.lineWrapping
                                   , EditorView.updateListener.of((v)=> {
                                       if(v.docChanged) {
                                           sendText(editor)
                                       }
                                     })
                                   ],
                               doc: ""

                               }),
                               parent: document.getElementById("editor-here")

                             })

                    this.dispatchEvent(new CustomEvent("editor-ready", { bubbles: true, composed: true, detail: editor }))
                    this.editor = editor
                    // this.editor.focus = editorFocus

                    // Inject base editor styles
                   // this.injectTheme("#ace_editor\\.css")

                    // this.editor.setTheme("ace/theme/twilight");  ///

//                    editor.getSession().on("change", (event) => {
//                        element.dispatchEvent(new CustomEvent("change", { bubbles: true, composed: true, detail: event }))
//                    })

                }



        console.log("THIS", this)


    }


    attributeChangedCallback(attr, oldVal, newVal) {

             console.log("attributeChangedCallback")

             function replaceAllText(editor, str) {
                         const currentValue = editor.state.doc.toString();
                         const endPosition = currentValue.length;

                         editor.dispatch({
                           changes: {
                             from: 0,
                             to: endPosition,
                             insert: str}
                         })
                     }

    //         if (!this._attached) {
    //             return false
    //         }
             switch (attr) {
                 case "yada":
                    console.log("yada", newVal)
//                 case "linenumber":
//                    console.log(attr)
//                    this.editor.scrollToLine(newVal, true, true, function () {});
//                    this.editor.gotoLine(newVal, 0, true);
//                    break
//                 case "searchkey":
//                    this.editor.$search.set({ needle: newVal });
//                    this.editor.found = this.editor.$search.findAll(this.editor.getSession())
//                    this.editor.searchIndex = 0
//                    if (this.editor.found[0] != null) {
//                            var  line =  this.editor.found[0].start.row + 1
//                            console.log("line", line)
//                            this.editor.scrollToLine(line, true, true, function () {});
//                            this.editor.gotoLine(line, 0, true);
//                      }
//
//
//                    break
//                 case "searchcount":
//                    console.log("searchcount", newVal)
//                    if (this.editor.found != null) {
//                          this.editor.searchIndex = (this.editor.searchIndex + 1) % this.editor.found.length
//                          var  line2 =  this.editor.found[this.editor.searchIndex].start.row + 1
//                          console.log("line2", line2)
//                          this.editor.scrollToLine(line2, true, true, function () {});
//                          this.editor.gotoLine(line2, 0, true);
//
//                      }
//                    break
//
                     case "text":
                          if (this.editor) { replaceAllText(this.editor, newVal); console.log("repaced source with", newVal) }
                          else {console.log("attr text", "this.editor not defined")}

//                             console.log("SOURCE!!!:", newVal)
//
//                         }
                     break
             }
         }


  }

customElements.define("codemirror-editor", CodemirrorEditor); // (2)


// const currentValue = editor.state.doc.toString();


