import React, { Component } from "react";
import "./Optin.css";

import {
  FaFacebookSquare,
  FaInstagram,
  FaGithub,
  FaTwitter,
} from "react-icons/fa";
import { SiLinktree } from "react-icons/si";



class Optin extends Component {
  modal() {
    const modal = document.getElementById("modal");
    modal.classList.toggle("is_open");
  }

  render() {
    return (
      <div className="optin">
        <p>Want to be the first to know when we launch?</p>
        <button onClick={() => this.modal()}>Click Me</button>
        <div id="modal">
          <div className="wrapper">
            <h3>Enter Your Email</h3>
            <div className="clearfix">
              <div className="col-8" />
              <div className="col-3" />
            </div>
          </div>
        </div>
        <br />
        <br />
        <div className="social_media">
        <a href={"https://github.com/pstanislau"}>
          <FaGithub />
        </a>
        <a
          href={"https://www.instagram.com/pedrostanislau/"}>
          <FaInstagram />
        </a>
        <a href={"https://twitter.com/pedrostanislau"}>
          <FaTwitter />
        </a>
        <a
          href={"https://facebook.com/pstanislau"}>
          <FaFacebookSquare />
        </a>
        <a href={"https://linktr.ee/pstanislau"}>
          <SiLinktree />
        </a>
      </div>
      <div className="copyright">
        <small>&copy; Tropa do Sábio. All rights reserved. 🧠</small>
      </div>
      </div>
    );
  }
}

export default Optin;
