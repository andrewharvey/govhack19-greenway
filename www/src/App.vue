<template>
  <v-app>
    <v-app-bar app>
      <v-toolbar-title class="headline text-uppercase">
        <span>Greenway</span>
        <span class="font-weight-light">Greater Sydney's Cool and Green Routes</span>
      </v-toolbar-title>
    </v-app-bar>

    <v-content>
        <v-menu
            v-model="menu"
            :nudgeRight="menuX"
            :nudgeBottom="menuY"
            attach="#map"
            absolute
            offset-y
            :left="menuLeft"
            :right="menuRight"
            :top="menuTop"
            :bottom="menuBottom"
            >
            <v-list dense>
                <v-list-tile @click="setTripOrigin">
                    <v-list-tile-avatar>
                        <v-icon>trip_origin</v-icon>
                    </v-list-tile-avatar>
                    <v-list-tile-content>
                        <v-list-tile-title>From</v-list-tile-title>
                    </v-list-tile-content>
                </v-list-tile>
                <v-list-tile @click="setTripWaypoint">
                    <v-list-tile-avatar>
                        <v-icon>add_circle</v-icon>
                    </v-list-tile-avatar>
                    <v-list-tile-content>
                        <v-list-tile-title>Via</v-list-tile-title>
                    </v-list-tile-content>
                </v-list-tile>
                <v-list-tile @click="setTripDestination">
                    <v-list-tile-avatar>
                        <v-icon>place</v-icon>
                    </v-list-tile-avatar>
                    <v-list-tile-content>
                        <v-list-tile-title>To</v-list-tile-title>
                    </v-list-tile-content>
                </v-list-tile>
            </v-list>
        </v-menu>
        <div id="panel">
        <v-container>
            <v-row no-gutters>
                <v-text-field
                    v-model="from"
                    label="From"
                    prepend-icon="trip_origin"
                    solo
                    ></v-text-field>
            </v-row>
            <v-row no-gutters>
                <v-text-field
                    v-model="to"
                    label="To"
                    prepend-icon="room"
                    solo
                    ></v-text-field>
            </v-row>
             <v-layout row wrap ma-4>
              <v-flex xs12>
                  <h4>Profile</h4>
              </v-flex>
              <v-flex xs12>
                  <v-btn-toggle v-model="mode" mandatory>
                      <v-tooltip bottom>
                          <template v-slot:activator="{ on }">
                              <v-btn flat v-on="on" value="cycling">
                                  <v-icon>directions_bike</v-icon>
                              </v-btn>
                          </template>
                          <span>Cycling</span>
                      </v-tooltip>
                      <v-tooltip bottom>
                          <template v-slot:activator="{ on }">
                              <v-btn flat v-on="on" value="walking">
                                  <v-icon>directions_walk</v-icon>
                              </v-btn>
                          </template>
                          <span>Walking</span>
                      </v-tooltip>
                  </v-btn-toggle>
              </v-flex>
          </v-layout>

        </v-container>
        </div>
        <div id="map"></div>
    </v-content>
  </v-app>
</template>

<script>
import mapboxgl from 'mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'

const urlParams = new URLSearchParams(window.location.search)

mapboxgl.accessToken = 'pk.eyJ1IjoiYWxhbnRnZW8tcHJlc2FsZXMiLCJhIjoiY2swOHlmOGZhMDM2cjNqcjcwd2xvYzVneSJ9.SOa3gAU7BfVtQuvuafgXAg'

export default {
    name: 'App',
    components: {
    },
    data: () => ({
        origin: null,
        destination: null,
        waypoints: [],

        // show map click menu
        menu: false,

        // menu position relative to map div in px
        menuX: 0,
        menuY: 0,

        // menu long, lat
        menuLL: null,

        // menu anchor location
        menuLeft: false,
        menuRight: false,
        menuTop: false,
        menuBottom: false
    }),
    mounted () {
        this.map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/alantgeo-presales/ck08wklxa1k831cp9izq84duz',
            center: [151.0057, -33.8401],
            zoom: 10,
            hash: true
        })

        this.map.on('load', this.mapLoaded);
    },
    methods: {
        mapLoaded: function () {
            this.map.on('contextmenu', this.contextClick)

            if (urlParams.has('origin')) {
                this.origin = urlParams.get('origin').split(',').map(Number)
            }
            if (urlParams.has('destination')) {
                this.destination = urlParams.get('destination').split(',').map(Number)
            }
        },
        contextClick: function (e) {
            this.menuX = e.point.x
            this.menuY = e.point.y
            this.menuLL = e.lngLat.toArray().map(coord => {
                return Number(coord.toFixed(5))
            })
            this.menu = true

            const mapElement = document.getElementById('map')

            if (e.point.x > mapElement.clientWidth / 2) {
                this.menuRight = false
                this.menuLeft = true
            } else {
                this.menuRight = true
                this.menuLeft = false
            }

            if (e.point.y > mapElement.clientHeight / 2) {
                this.menuTop = true
                this.menuBottom = false
            } else {
                this.menuTop = false
                this.menuBottom = true
            }
        },

    }
};
</script>
<style>
html { overflow-y: auto !important; }

#panel {
    position: absolute;
    width: 400px;
    left: 0;
    height: 100%;

    overflow-y: scroll;
}
#map {
    position: absolute;
    height: 100%;
    left: 400px;
    right: 0;
}
</style>
