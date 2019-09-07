<template>
  <v-app>
    <v-app-bar app dark color="primary" >
      <v-toolbar-title class="headline text-uppercase">
        <span class="font-weight-bold">Greenway: </span>
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
                <v-list-item @click="setTripOrigin">
                    <v-list-item-icon>
                        <v-icon>trip_origin</v-icon>
                    </v-list-item-icon>
                    <v-list-item-content>
                        <v-list-item-title>From</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>
                <v-list-item @click="setTripWaypoint">
                    <v-list-item-icon>
                        <v-icon></v-icon>
                    </v-list-item-icon>
                    <v-list-item-content>
                        <v-list-item-title>via</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>
                <v-list-item @click="setTripDestination">
                    <v-list-item-icon>
                        <v-icon>place</v-icon>
                    </v-list-item-icon>
                    <v-list-item-content>
                        <v-list-item-title>To</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>
            </v-list>
        </v-menu>
        <div id="panel">
            <v-img src="logo.png"></v-img>
            <v-container>
                <v-layout>
                    <v-row no-gutters>
                        <v-text-field
                            v-model="origin"
                            label="From"
                            prepend-icon="trip_origin"
                            solo
                            ></v-text-field>
                    </v-row>
                </v-layout>
                <v-layout>
                    <v-row no-gutters>
                        <v-text-field
                            v-model="destination"
                            label="To"
                            prepend-icon="room"
                            solo
                            ></v-text-field>
                    </v-row>
                </v-layout>
                <v-layout row wrap ma-4>
                    <v-flex xs12>
                        <h4>Profile: <i>{{mode}}</i></h4>
                    </v-flex>
                    <v-flex xs12>
                        <v-btn-toggle v-model="mode" mandatory>
                            <v-tooltip bottom>
                                <template v-slot:activator="{ on }">
                                    <v-btn v-on="on" value="car">
                                        <v-icon>directions_car</v-icon>
                                    </v-btn>
                                </template>
                                <span>Driving</span>
                            </v-tooltip>
                            <v-tooltip bottom>
                                <template v-slot:activator="{ on }">
                                    <v-btn v-on="on" value="bicycle">
                                        <v-icon>directions_bike</v-icon>
                                    </v-btn>
                                </template>
                                <span>Cycling</span>
                            </v-tooltip>
                            <v-tooltip bottom>
                                <template v-slot:activator="{ on }">
                                    <v-btn v-on="on" value="foot">
                                        <v-icon>directions_walk</v-icon>
                                    </v-btn>
                                </template>
                                <span>Walking</span>
                            </v-tooltip>
                            <v-tooltip bottom>
                                <template v-slot:activator="{ on }">
                                    <v-btn v-on="on" value="footcool">
                                        <v-icon color="green">directions_walk</v-icon>
                                    </v-btn>
                                </template>
                                <span>Walking</span>
                            </v-tooltip>
                        </v-btn-toggle>
                    </v-flex>
                </v-layout>
                <v-layout row wrap ma-4>
                    <v-flex xs12>
                        <h4>Layers</h4>
                    </v-flex>
                    <v-flex xs12>
                        <v-list>
                            <v-list-item-group v-model="layer">
                                <v-list-item
                                    v-for="(item, i) in layers"
                                    :key="i"
                                    :color="item.color"
                                    >
                                    <v-list-item-icon>
                                        <v-icon v-text="item.icon"></v-icon>
                                    </v-list-item-icon>
                                    <v-list-item-content>
                                        <v-list-item-title v-text="item.text"></v-list-item-title>
                                    </v-list-item-content>
                                </v-list-item>
                            </v-list-item-group>
                        </v-list>
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
import axios from 'axios';

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

        routes: null,

        mode: 'foot',

        layer: 0,
        layers: [
            {
                icon: '',
                text: 'None'
            },
            {
                icon: 'local_florist',
                key: 'vgecover',
                text: 'Urban Vegetation Cover',
                color: 'green'
            },
            {
                icon: 'wb_sunny',
                key: 'uhi',
                text: 'Urban Heat Island',
                color: 'blue'
            }
        ],

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
            zoom: 8,
            hash: true
        })
        this.map.addControl(new mapboxgl.NavigationControl());
        this.map.addControl(new mapboxgl.GeolocateControl());
        this.map.on('load', this.mapLoaded);

        const originSVG = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
        originSVG.setAttributeNS(null, 'display', 'block')
        originSVG.setAttributeNS(null, 'width', '20px')
        originSVG.setAttributeNS(null, 'height', '20px')
        originSVG.setAttributeNS(null, 'viewBox', '0 0 20 20')

        const originSVGCircle = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
        originSVGCircle.setAttributeNS(null, 'r', '8.5')
        originSVGCircle.setAttributeNS(null, 'cy', '10')
        originSVGCircle.setAttributeNS(null, 'cx', '10')
        originSVGCircle.setAttributeNS(null, 'fill', this.$vuetify.theme.themes.light.primary)
        originSVGCircle.setAttributeNS(null, 'stroke', '#ffffff')
        originSVGCircle.setAttributeNS(null, 'stroke-width', '2.0')

        originSVG.appendChild(originSVGCircle)

        this.originMarker = new mapboxgl.Marker({
            element: originSVG,
            draggable: true
        })

        this.destinationMarker = new mapboxgl.Marker({
            color: this.$vuetify.theme.themes.light.primary,
            draggable: true
        })

        this.originMarker.on('dragend', () => {
            this.origin = this.originMarker
                .getLngLat()
                .toArray()
                .map(coord => {
                    return Number(coord.toFixed(5))
                })
        })
        this.destinationMarker.on('dragend', () => {
            this.destination = this.destinationMarker
                .getLngLat()
                .toArray()
                .map(coord => {
                    return Number(coord.toFixed(5))
                })
        })
    },
    watch: {
        mode: function (mode) {
            this.updateDirections()

            urlParams.set('mode', mode)
            this.updateUrl()
        },
        waypoints: function (waypoints) {
            this.updateDirections()
        },
        origin: function (origin) {
            this.originMarker
                .setLngLat(origin)
                .addTo(this.map);

            this.updateDirections()

            urlParams.set('origin', origin.join(','))
            this.updateUrl()
        },
        destination: function (destination) {
            this.destinationMarker
                .setLngLat(destination)
                .addTo(this.map);

            this.updateDirections()

            urlParams.set('destination', destination.join(','))
            this.updateUrl()
        },
        routes: function (routes) {
            this.map.getSource('routes').setData(routes)
        },
        layer: function (layer) {
            switch (layer) {
                case 0:
                    this.map.setLayoutProperty('vegcover', 'visibility', 'none');
                    this.map.setLayoutProperty('uhi', 'visibility', 'none');
                    break;
                case 1:
                    this.map.setLayoutProperty('vegcover', 'visibility', 'visible');
                    this.map.setLayoutProperty('uhi', 'visibility', 'none');
                    break;
                case 2:
                    this.map.setLayoutProperty('vegcover', 'visibility', 'none');
                    this.map.setLayoutProperty('uhi', 'visibility', 'visible');
                    break;
            }
        }
    },
    computed: {
        coordinatesString: function () {
            return [this.origin, ...this.waypoints, this.destination].map((coord) => {
                    return coord.join(',')
                }).join(';')
        }
    },
    methods: {
        updateUrl: () => {
            history.pushState(null, '', window.location.pathname + '?' + urlParams.toString())
        },
        mapLoaded: function () {
            this.map.on('contextmenu', this.contextClick)

            if (urlParams.has('origin')) {
                this.origin = urlParams.get('origin').split(',').map(Number)
            }
            if (urlParams.has('destination')) {
                this.destination = urlParams.get('destination').split(',').map(Number)
            }

            this.map.addSource('routes', {
                type: 'geojson',
                data: { type: 'FeatureCollection', features: [] }
            })
            this.map.addLayer({
                type: 'line',
                id: 'route-halo',
                source: 'routes',
                paint: {
                    'line-color': '#ffffff',
                    'line-width': 8
                },
                layout: {
                    'line-join': 'round'
                }
            })
            this.map.addLayer({
                type: 'line',
                id: 'route',
                source: 'routes',
                paint: {
                    'line-color': this.$vuetify.theme.themes.light.primary,
                    'line-width': 4
                },
                layout: {
                    'line-join': 'round'
                }
            })
        },
        setTripOrigin: function () {
            this.origin = this.menuLL
        },
        setTripWaypoint: function () {
            this.waypoints.push(this.menuLL)
        },
        setTripDestination: function () {
            this.destination = this.menuLL
        },
        updateDirections: function () {
            if (this.origin && this.destination) {
                console.log(this.coordinatesString)
                axios.get(`http://greenway.microburbs.com.au/route/v1/${this.mode}/${this.coordinatesString}?geometries=geojson`)
                    .then((res) => {
                        if (res && res.data && res.data.code && res.data.code === 'Ok' && res.data.routes && res.data.routes.length) {
                            this.routes = {
                                type: 'FeatureCollection',
                                features: res.data.routes.map((route) => {
                                    return {
                                        type: 'Feature',
                                        properties: {},
                                        geometry: route.geometry
                                    }
                                })
                            }
                        }
                        console.log(res);
                        console.log('weight: ', res.data.routes[0].weight)
                        console.log('duration: ', res.data.routes[0].duration)
                    })
                    .catch((err) => {
                        console.log(err);
                    })
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

    overflow-y: overlay;
}
#map {
    position: absolute;
    height: 100%;
    left: 400px;
    right: 0;
}
</style>
